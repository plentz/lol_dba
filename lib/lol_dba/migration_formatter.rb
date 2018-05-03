module LolDba
  class MigrationFormatter
    def self.puts_migration_content(migration_name, indexes, warning_messages)
      puts warning_messages
      formated_indexes = format_for_migration(indexes)
      if formated_indexes.blank?
        puts 'Yey, no missing indexes found!'
      else
        puts form_migration_content(migration_name, formated_indexes)
      end
    end

    def self.format_for_migration(missing_indexes)
      add = []
      missing_indexes.each do |table_name, keys_to_add|
        keys_to_add.each do |key|
          next if key.blank?
          add << format_index(table_name, key)
        end
      end
      add
    end

    def self.format_index(table_name, key)
      if key.is_a?(Array)
        keys = key.collect { |col| ":#{col}" }
        "add_index :#{table_name}, [#{keys.join(', ')}]"
      else
        "add_index :#{table_name}, :#{key}"
      end
    end

    def self.form_migration_content(migration_name, formated_indexes)
      <<-EOM
* TIP: if you have a problem with the index name('index name too long'), you can
solve with the :name option. Something like :name => 'my_index'.
* run `rails g migration #{migration_name}` and add the following content:

    class #{migration_name} < ActiveRecord::Migration
      def change
        #{formated_indexes.sort.uniq.join("\n        ")}
      end
    end
EOM
    end
  end
end
