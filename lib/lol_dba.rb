module LolDba

  require "lol_dba/writer"
  require "lol_dba/migration"
  require "lol_dba/railtie.rb" if defined?(Rails)

  def self.form_migration_content(migration_name, index_array)
    migration = <<EOM
* run `rails g migration #{migration_name}` and add the following content:


    class #{migration_name} < ActiveRecord::Migration
      def change
        #{index_array.sort.uniq.join("\n        ")}
      end
    end
EOM
  end

  def self.get_through_foreign_key(target_class, reflection_options)
    # has_many :through
    reflection = target_class.reflections[reflection_options.options[:through].to_s]

    # has_and_belongs_to_many
    reflection = reflection_options unless reflection

    # Guess foreign key?
    if reflection.options[:foreign_key]
      reflection.options[:foreign_key]
    else
      "#{target_class.name.tableize.singularize}_id"
    end
  end

  def self.tables
    ::ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Base.connection.data_sources : ActiveRecord::Base.connection.tables
  end

  def self.validate_and_sort_indexes(indexes_required)
    missing_indexes = {}
    warning_messages = ""
    indexes_required.each do |table_name, foreign_keys|
      next if foreign_keys.blank?
      begin
        if tables.include?(table_name.to_s)
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
    missing_indexes.each do |table_name, keys_to_add|
      keys_to_add.each do |key|
        next if key.blank?
        next if key_exists?(table_name,key)
        if key.is_a?(Array)
          keys = key.collect {|k| ":#{k}"}
          add << "add_index :#{table_name}, [#{keys.join(', ')}]"
        else
          add << "add_index :#{table_name}, :#{key}"
        end
      end
    end
    return add
  end

  def self.check_for_indexes(migration_format = false)
    if defined?(Rails) && !Rails.env.test?
      Rails.application.eager_load!
    end

    model_classes = []
    ObjectSpace.each_object(Module) do |obj|
      if Class == obj.class && obj != ActiveRecord::Base && obj.ancestors.include?(ActiveRecord::Base) && (!defined?(ActiveRecord::SessionStore::Session) || obj != ActiveRecord::SessionStore::Session)
        model_classes << obj
      end
    end

    @index_migrations = Hash.new([])

    model_classes.each do |class_name|
      unless class_name.descends_from_active_record?
        index_name = [class_name.inheritance_column, class_name.base_class.primary_key].sort
        @index_migrations[class_name.base_class.table_name] += [index_name]
      end
      reflections = class_name.reflections.stringify_keys
      reflections.each_pair do |reflection_name, reflection_options|
        begin
          index_name = ""
          case reflection_options.macro
          when :belongs_to
            # polymorphic?
            table_name = class_name.table_name
            if reflection_options.options[:polymorphic]
              poly_type = "#{reflection_options.name.to_s}_type"
              poly_id = "#{reflection_options.name.to_s}_id"
              index_name = [poly_type, poly_id].sort
            else
              foreign_key = reflection_options.options[:foreign_key]
              foreign_key ||= reflection_options.respond_to?(:primary_key_name) ? reflection_options.primary_key_name : reflection_options.foreign_key
              next if foreign_key == "left_side_id" # not a clue why rails 4.1+ creates this left_side_id thing
              index_name = foreign_key.to_s
            end
          when :has_and_belongs_to_many
            table_name = reflection_options.options[:join_table]
            table_name ||= [class_name.table_name, reflection_name.to_s].sort.join('_')
            association_foreign_key = reflection_options.options[:association_foreign_key] ||= "#{reflection_name.to_s.singularize}_id"

            foreign_key = get_through_foreign_key(class_name, reflection_options)
            index_name = [association_foreign_key, foreign_key].map(&:to_s).sort
          when :has_many
            through = reflection_options.options[:through]
            next unless through && reflections[through.to_s] # has_many tables are threaten by the other side of the relation

            through_class = reflections[through.to_s].klass
            table_name = through_class.table_name

            foreign_key = get_through_foreign_key(class_name, reflection_options)

            through_reflections = through_class.reflections.stringify_keys
            if source = reflection_options.options[:source]
              association_reflection = through_reflections[source.to_s]
              next if association_reflection.options[:polymorphic]
              association_foreign_key = get_through_foreign_key(association_reflection.klass, reflection_options)
            elsif belongs_to_reflections = through_reflections[reflection_name.singularize]
              # go to joining model through has_many and find belongs_to
              association_foreign_key = belongs_to_reflections.options[:foreign_key]
            end

            #FIXME currently we don't support :through => :another_regular_has_many_and_non_through_relation
            next if association_foreign_key.nil?
            index_name = [association_foreign_key, foreign_key].map(&:to_s).sort
          end

          unless index_name == "" || reflection_options.options.include?(:class)
            @index_migrations[table_name.to_s] += [index_name]
          end

        rescue Exception => e
          puts "Some errors here:"
          puts "Please, create an issue with the following information here https://github.com/plentz/lol_dba/issues:"
          puts "***************************"
          puts "Class: #{class_name}"
          puts "Association type: #{reflection_options.macro}"
          puts "Association options: #{reflection_options.options}"
          puts "Exception: #{e.message}"
          e.backtrace.each{|trace| puts trace}
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
    add = form_data_for_migration(indexes)
    if add.blank?
      puts "Yey, no missing indexes found!"
    else
      tip = "* TIP: if you have a problem with the index name('index name too long') you can solve with the :name option. "
      tip += "Something like :name => 'my_index'."
      puts tip
      puts form_migration_content(migration_name, add)
    end
  end

  def self.simple_migration
    missing_indexes, warning_messages = check_for_indexes(true)

    puts_migration_content("AddMissingIndexes", missing_indexes, warning_messages)
  end
end
