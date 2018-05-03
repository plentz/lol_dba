module LolDba
  require 'lol_dba/writer'
  require 'lol_dba/migration'
  require 'lol_dba/migration_formatter'
  require 'lol_dba/rails_compatibility'
  require 'lol_dba/railtie.rb' if defined?(Rails)

  def self.get_through_foreign_key(target_class, reflection_options)
    # has_many :through
    reflection = target_class.reflections[reflection_options.options[:through].to_s]

    # has_and_belongs_to_many
    reflection ||= reflection_options

    # Guess foreign key?
    if reflection.options[:foreign_key]
      reflection.options[:foreign_key]
    else
      "#{target_class.name.tableize.singularize}_id"
    end
  end

  def self.tables
    LolDba::RailsCompatibility.tables
  end

  def self.validate_and_sort_indexes(indexes_required)
    missing_indexes = {}
    warning_messages = ''
    indexes_required.each do |table_name, foreign_keys|
      next if foreign_keys.blank?
      if tables.include?(table_name.to_s)
        keys_to_add = foreign_keys.uniq - existing_indexes(table_name)
        missing_indexes[table_name] = keys_to_add unless keys_to_add.empty?
      else
        warning_messages << "BUG: table '#{table_name}' does not exist, please report this bug.\n    "
      end
    end
    [missing_indexes, warning_messages]
  end

  def self.existing_indexes(table_name)
    table_indexes = ActiveRecord::Base.connection.indexes(table_name.to_sym)
    existing = table_indexes.collect do |index|
      index.columns.size > 1 ? index.columns : index.columns.first
    end
    existing += Array(ActiveRecord::Base.connection.primary_key(table_name.to_s))
  end

  def self.model_classes
    ActiveRecord::Base.descendants.select do |obj|
      Class == obj.class && session_store?(obj)
    end
  end

  def self.session_store?(obj)
    !defined?(ActiveRecord::SessionStore::Session) || obj != ActiveRecord::SessionStore::Session
  end

  def self.check_for_indexes
    Rails.application.eager_load! if defined?(Rails) && !Rails.env.test?

    @index_migrations = Hash.new([])

    model_classes.each do |class_name|
      unless class_name.descends_from_active_record?
        index_name = [class_name.inheritance_column, class_name.base_class.primary_key].sort
        @index_migrations[class_name.base_class.table_name] += [index_name]
      end
      reflections = class_name.reflections.stringify_keys
      reflections.each_pair do |reflection_name, reflection_options|
        begin
          index_name = ''
          case reflection_options.macro
          when :belongs_to
            # polymorphic?
            table_name = class_name.table_name
            if reflection_options.options[:polymorphic]
              poly_type = "#{reflection_options.name}_type"
              poly_id = "#{reflection_options.name}_id"
              index_name = [poly_type, poly_id].sort
            else
              foreign_key = reflection_options.options[:foreign_key]
              foreign_key ||= reflection_options.respond_to?(:primary_key_name) ? reflection_options.primary_key_name : reflection_options.foreign_key
              next if foreign_key == 'left_side_id' # not a clue why rails 4.1+ creates this left_side_id thing
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

            # FIXME: currently we don't support :through => :another_regular_has_many_and_non_through_relation
            next unless association_foreign_key.present?
            index_name = [association_foreign_key, foreign_key].map(&:to_s).sort
          end

          unless index_name == '' || reflection_options.options.include?(:class)
            @index_migrations[table_name.to_s] += [index_name]
          end
        rescue Exception => e
          puts 'Some errors here:'
          puts 'Please, create an issue with the following information here https://github.com/plentz/lol_dba/issues:'
          puts '***************************'
          puts "Class: #{class_name}"
          puts "Association type: #{reflection_options.macro}"
          puts "Association options: #{reflection_options.options}"
          puts "Exception: #{e.message}"
          e.backtrace.each { |trace| puts trace }
        end
      end # case end
    end # each_pair end

    validate_and_sort_indexes(@index_migrations)
  end

  def self.simple_migration
    MigrationFormatter.new(check_for_indexes).puts_migration_content
  end
end
