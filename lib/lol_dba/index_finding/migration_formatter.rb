module LolDba
  class MigrationFormatter
    def initialize(indexes)
      @indexes = indexes
    end

    def puts_migration_content
      formated_indexes = format_for_migration(@indexes)
      if formated_indexes.blank?
        puts 'Yey, no missing indexes found!'
      else
        puts migration_instructions(formated_indexes)
      end
    end

    def format_for_migration(missing_indexes)
      add = []
      missing_indexes.each do |table_name, keys_to_add|
        keys_to_add.each do |key|
          next if key.blank?
          add << format_index(table_name, key)
        end
      end
      add
    end

    def format_index(table_name, key)
      if key.is_a?(Array)
        keys = key.collect { |col| ":#{col}" }
        "add_index :#{table_name}, [#{keys.join(', ')}]"
      else
        "add_index :#{table_name}, :#{key}"
      end
    end

    def migration_instructions(formated_indexes)
      <<-MIGRATION
* TIP: if you have a problem with the index name('index name too long'), you can
solve with the :name option. Something like :name => 'my_index'.
* run `rails g migration AddMissingIndexes` and add the following content:

    class AddMissingIndexes < ActiveRecord::Migration
      def change
        #{formated_indexes.sort.uniq.join("\n        ")}
      end
    end
MIGRATION
    end
  end
end
