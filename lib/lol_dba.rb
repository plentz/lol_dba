module LolDba

  require "lol_dba/writer"
  require "lol_dba/migration"
  require "lol_dba/railtie.rb" if defined?(Rails)

  def self.form_migration_content(migration_name, add_index_array, del_index_array)
    migration = <<EOM
    ## run `rails g migration AddMissingIndexes` and add the following content


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
              foreign_key = reflection_options.options[:foreign_key] ||= reflection_options.respond_to?(:primary_key_name) ? reflection_options.primary_key_name : reflection_options.foreign_key
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
            next if association_foreign_key.nil?
            composite_keys = [association_foreign_key.to_s, foreign_key.to_s]
            @index_migrations[table_name] += [composite_keys] unless @index_migrations[table_name].include?(composite_keys)
            @index_migrations[table_name] += [composite_keys.reverse] unless @index_migrations[table_name].include?(composite_keys.reverse)
          end
        rescue Exception => e
          p "Some errors here:"
          p "Please add info after this string in to https://github.com/plentz/lol_dba/issues"
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
end
