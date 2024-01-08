module LolDba
  class IndexFinder
    def self.run
      missing_indexes = check_for_indexes
      MigrationFormatter.new(missing_indexes).puts_migration_content
      missing_indexes.any?
    end

    def self.check_for_indexes
      eager_load_if_needed

      required_indexes = Hash.new([])

      model_classes.each do |model_class|
        unless model_class.descends_from_active_record?
          index_name = [model_class.inheritance_column, model_class.base_class.primary_key].sort
          required_indexes[model_class.base_class.table_name] += [index_name]
        end
        reflections = model_class.reflections.stringify_keys
        reflections.each_pair do |reflection_name, reflection_options|
          begin
            clazz = RelationInspectorFactory.for(reflection_options.macro)
            next unless clazz.present?
            inspector = clazz.new(model_class, reflection_options,
                                  reflection_name)
            columns = inspector.relation_columns

            unless columns.nil? || reflection_options.options.include?(:class)
              required_indexes[inspector.table_name.to_s] += [columns]
            end
          rescue StandardError => exception
            LolDba::ErrorLogging.log(model_class, reflection_options, exception)
          end
        end
      end

      missing_indexes(required_indexes)
    end

    def self.missing_indexes(indexes_required)
      missing_indexes = {}
      indexes_required.each do |table_name, foreign_keys|
        next if foreign_keys.blank? || !tables.include?(table_name.to_s)
        keys_to_add = foreign_keys.uniq - existing_indexes(table_name)
        missing_indexes[table_name] = keys_to_add unless keys_to_add.empty?
      end
      missing_indexes
    end

    def self.tables
      LolDba::RailsCompatibility.tables
    end

    def self.existing_indexes(table_name)
      table_indexes(table_name) + primary_key(table_name)
    end

    def self.table_indexes(table_name)
      indexes = ActiveRecord::Base.connection.indexes(table_name.to_sym)
      indexes.collect do |index|
        if index.columns.is_a?(String)
          # eg. gin, tsvector...
          index.columns
        else
          index.columns.size > 1 ? index.columns.sort : index.columns.first
        end
      end
    end

    def self.primary_key(table_name)
      Array(ActiveRecord::Base.connection.primary_key(table_name.to_s))
    end

    def self.model_classes
      ActiveRecord::Base.descendants.select do |obj|
        Class == obj.class && session_store?(obj)
      end
    end

    def self.session_store?(obj)
      !defined?(ActiveRecord::SessionStore::Session) || obj != ActiveRecord::SessionStore::Session
    end

    def self.eager_load_if_needed
      Rails.application.eager_load! if defined?(Rails) && !Rails.env.test?
    end
  end
end
