module RailsIndexes

  require "rails_indexes/railtie.rb" if defined?(Rails)

  def self.form_migration_content(migration_name, add_index_array, del_index_array)
    migration = <<EOM
    ## run `rails g migrate AddMissingIndexes` and add the following content


    class #{migration_name} < ActiveRecord::Migration
      def self.up
        #{add_index_array.uniq.join("\n        ")}
      end

      def self.down
        #{del_index_array.uniq.join("\n        ")}
      end
    end
EOM
  end

  def self.get_through_foreign_key(target_class, reflection_options)
    if target_class.reflections[reflection_options.options[:through]]
      # has_many :through
      reflection = target_class.reflections[reflection_options.options[:through]]
    else
      # has_and_belongs_to_many
      reflection = reflection_options
    end
    # Guess foreign key?
    if reflection.options[:foreign_key]
      association_foreign_key = reflection.options[:foreign_key]
    elsif reflection.options[:class_name]
      association_foreign_key = reflection.options[:class_name].foreign_key
    else
      association_foreign_key = "#{target_class.name.tableize.singularize}_id"
    end
  end

  def self.validate_and_sort_indexes(indexes_required)
    missing_indexes = {}
    warning_messages = ""
    indexes_required.each do |table_name, foreign_keys|
      next if foreign_keys.blank?
      begin
        if ActiveRecord::Base.connection.tables.include?(table_name.to_s)
          existing_indexes = ActiveRecord::Base.connection.indexes(table_name.to_sym).collect {|index| index.columns.size > 1 ? index.columns : index.columns.first}
          existing_indexes += Array(ActiveRecord::Base.connection.primary_key(table_name.to_s))
          keys_to_add = foreign_keys.uniq - existing_indexes
          missing_indexes[table_name] = keys_to_add unless keys_to_add.empty?
        else
          warning_messages << "BUG: table '#{table_name.to_s}' does not exist, please report this bug.\n    "
        end
      rescue Exception => e
        puts "ERROR: #{e}"
      end
    end
    return missing_indexes, warning_messages
  end

  def self.form_data_for_migration(missing_indexes)
    add = []
    remove = []
    missing_indexes.each do |table_name, keys_to_add|
      keys_to_add.each do |key|
        next if key.blank?
        next if key_exists?(table_name,key)
        if key.is_a?(Array)
          keys = key.collect {|k| ":#{k}"}
          add << "add_index :#{table_name}, [#{keys.join(', ')}]"
          remove << "remove_index :#{table_name}, :column => [#{keys.join(', ')}]"
        else
          add << "add_index :#{table_name}, :#{key}"
          remove << "remove_index :#{table_name}, :#{key}"
        end
      end
    end
    return add, remove
  end

  def self.check_for_indexes(migration_format = false)
    Dir.glob(Rails.root + "app/models/**/*.rb").each {|file| require file }

    model_classes = []
    ActiveRecord::Base.subclasses.each do |klass|
      if !klass.abstract_class? && klass != ActiveRecord::SessionStore::Session
        model_classes << klass
      end
    end

    @index_migrations = Hash.new([])

    model_classes.each do |class_name|

      # check if this is an STI child instance
      #if class_name.base_class.name != class_name.name && (class_name.column_names.include?(class_name.base_class.inheritance_column) || class_name.column_names.include?(class_name.inheritance_column))
      unless class_name < ActiveRecord::Base
        # add the inharitance column on the parent table
        # index migration for STI should require both the primary key and the inheritance_column in a composite index.
        @index_migrations[class_name.base_class.table_name] += [[class_name.inheritance_column, class_name.base_class.primary_key].sort] unless @index_migrations[class_name.base_class.table_name].include?([class_name.base_class.inheritance_column].sort)
      end

      class_name.reflections.each_pair do |reflection_name, reflection_options|
        begin
          case reflection_options.macro
          when :belongs_to
            # polymorphic?
            @table_name = class_name.table_name.to_s
            if reflection_options.options.has_key?(:polymorphic) && (reflection_options.options[:polymorphic] == true)
              poly_type = "#{reflection_options.name.to_s}_type"
              poly_id = "#{reflection_options.name.to_s}_id"
              @index_migrations[@table_name.to_s] += [[poly_type, poly_id].sort] unless @index_migrations[@table_name.to_s].include?([poly_type, poly_id].sort)
            else
              foreign_key = reflection_options.options[:foreign_key] ||= reflection_options.foreign_key
              @index_migrations[@table_name.to_s] += [foreign_key] unless @index_migrations[@table_name.to_s].include?(foreign_key)
            end
          when :has_and_belongs_to_many
            table_name = reflection_options.options[:join_table] ||= [class_name.table_name, reflection_name.to_s].sort.join('_')

            association_foreign_key = reflection_options.options[:association_foreign_key] ||= "#{reflection_name.to_s.singularize}_id"

            foreign_key = get_through_foreign_key(class_name, reflection_options)

            composite_keys = [association_foreign_key, foreign_key]

            @index_migrations[table_name.to_s] += [composite_keys] unless @index_migrations[table_name].include?(composite_keys)
            @index_migrations[table_name.to_s] += [composite_keys.reverse] unless @index_migrations[table_name].include?(composite_keys.reverse)
          when :has_many
            # has_many tables are threaten by the other side of the relation
            next unless reflection_options.options[:through]

            table_name = reflection_options.options[:through].to_s.singularize.camelize.constantize.table_name

            foreign_key = get_through_foreign_key(class_name, reflection_options)

            if reflection_options.options[:source]
              association_class = reflection_options.options[:source].to_s.singularize.camelize.constantize
              association_foreign_key = get_through_foreign_key(association_class, reflection_options)
            else
              # go to joining model through has_many and find belongs_to
              blg_to_reflection = class_name.reflections[reflection_options.options[:through]]
              if blg_to_reflection.options[:class_name]
                # has_many :class_name
                blg_to_class = blg_to_reflection.options[:class_name].constantize
              else
                # has_many
                blg_to_class = blg_to_reflection.name.to_s.singularize.camelize.constantize
              end

              #multiple level :through relation, can be ignored for now(it will be checked in the right relation)
              next if blg_to_class.reflections[reflection_name.to_s.singularize.to_sym].nil?

              # get foreign_key from belongs_to
              association_foreign_key = blg_to_class.reflections[reflection_name.to_s.singularize.to_sym].options[:foreign_key]
            end

            #FIXME currently we don't support :through => :another_regular_has_many_and_non_through_relation
            #puts "#{class_name} - #{reflection_options.macro} - #{table_name} >" + composite_keys.inspect
            next if association_foreign_key.nil?
            composite_keys = [association_foreign_key.to_s, foreign_key.to_s]
            @index_migrations[table_name] += [composite_keys] unless @index_migrations[table_name].include?(composite_keys)
            @index_migrations[table_name] += [composite_keys.reverse] unless @index_migrations[table_name].include?(composite_keys.reverse)
          end
        rescue Exception => e
          p "Some errors here:"
          p "Please add info after this string in to https://github.com/plentz/rails_indexes/issues"
          p "Class: #{class_name}"
          p "Association type: #{reflection_options.macro}"
          p "Association options: #{reflection_options.options}"
          p e.message
          p e.backtrace.inspect
        end
      end # case end
    end # each_pair end

    missing_indexes, warning_messages = validate_and_sort_indexes(@index_migrations)

  end

  def self.scan_finds

    # Collect all files that can contain queries, in app/ directories (includes plugins and such)
    # TODO: add lib too ?
    file_names = []

    Dir.chdir(Rails.root) do
      file_names = Dir["**/app/**/*.rb"].uniq.reject {|file_with_path| file_with_path.include?('test')}
    end

    @indexes_required = Hash.new([])

    # Scan each file
    file_names.each do |file_name|
      current_file = File.open(File.join(Rails.root, file_name), 'r')
      begin
        current_model_name = File.basename(file_name).sub(/\.rb$/,'').camelize
      rescue
        # No-op
      end

      # by default, try to add index on primary key, based on file name
      # this will fail if the file is not a model file

      klass = current_model_name.split('::').inject(Object){ |klass,part| klass.const_get(part) } rescue next
      next if !klass.present? || klass < ActiveRecord::Base && klass.abstract_class?

      # Scan each line
      current_file.each { |line| check_line_for_find_indexes(file_name, line) }
    end

    missing_indexes, warning_messages = validate_and_sort_indexes(@indexes_required)

  end

  # Check line for find* methods (include find_all, find_by and just find)
  def self.check_line_for_find_indexes(file_name, line)
    # TODO: Assumes that you have a called on #find. you can actually call #find without a caller in a model code. ex:
    # def something
    #   find(self.id)
    # end
    #
    # find_regexp = Regexp.new(/([A-Z]{1}[A-Za-z]+|self).(find){1}((_all){0,1}(_by_){0,1}([A-Za-z_]+))?\(([0-9A-Za-z"\':=>. \[\]{},]*)\)/)

    find_regexp = Regexp.new(/(([A-Z]{1}[A-Za-z]+|self).)?(find){1}((_all){0,1}(_by_){0,1}([A-Za-z_]+))?\(([0-9A-Za-z"\':=>. \[\]{},]*)\)/)

    # If line matched a finder
    if matches = find_regexp.match(line)

      model_name, column_names, options = matches[2], matches[7], matches[8]

      # if the finder class is "self" or empty (can be a simple "find()" in a model)
      if model_name == "self" || model_name.blank?
        model_name = File.basename(file_name).sub(/\.rb$/,'').camelize
        table_name = model_name.constantize.table_name
      else
        if model_name.respond_to?(:constantize)
          if model_name.constantize.respond_to?(:table_name)
            table_name = model_name.constantize.table_name
          end
        end
      end

      # Check that all prerequisites are met
      if model_name.present? && table_name.present? && model_name.constantize.ancestors.include?(ActiveRecord::Base)
        primary_key = model_name.constantize.primary_key
        @indexes_required[table_name] += [primary_key] unless @indexes_required[table_name].include?(primary_key)

        if column_names.present?
          column_names = column_names.split('_and_')

          # remove find_by_sql references.
          column_names.delete("sql")

          column_names = model_name.constantize.column_names & column_names

          # Check if there were more than 1 column
          if column_names.size == 1
            column_name = column_names.first
            @indexes_required[table_name] += [column_name] unless @indexes_required[table_name].include?(column_name)
          else
            @indexes_required[table_name] += [column_names] unless @indexes_required[table_name].include?(column_names)
            @indexes_required[table_name] += [column_names.reverse] unless @indexes_required[table_name].include?(column_names.reverse)
          end
        end
      end
    end
  end

  def self.key_exists?(table,key_columns)
    result = (Array(key_columns) - ActiveRecord::Base.connection.indexes(table).map { |i| i.columns }.flatten)
    #FIXME: Primary key always indexes, but ActiveRecord::Base.connection.indexes not show it!
    result = result - Array(ActiveRecord::Base.connection.primary_key(table)) if result
    result.empty?
  end

  def self.puts_migration_content(migration_name, indexes, warning_messages)
    puts warning_messages
    if indexes.keys.empty?
      puts "Yey, no missing indexes found!"
    else
      add, remove = form_data_for_migration(indexes)
      puts form_migration_content(migration_name, add, remove)
    end
  end

  def self.simple_migration
    missing_indexes, warning_messages = check_for_indexes(true)

    puts_migration_content("AddMissingIndexes", missing_indexes, warning_messages)
  end

  def self.ar_find_indexes(migration_mode=true)
    find_indexes, warning_messages = self.scan_finds
    return find_indexes, warning_messages unless migration_mode

    puts_migration_content("AddFindsMissingIndexes", find_indexes, warning_messages)
  end
end
