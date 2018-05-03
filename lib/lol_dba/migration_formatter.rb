module LolDba
  class MigrationFormatter
    def self.puts_migration_content(migration_name, indexes, warning_messages)
      puts warning_messages
      add = format_for_migration(indexes)
      if add.blank?
        puts 'Yey, no missing indexes found!'
      else
        tip = "* TIP: if you have a problem with the index name('index name too long') you can solve with the :name option. "
        tip += "Something like :name => 'my_index'."
        puts tip
        puts form_migration_content(migration_name, add)
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

    def self.form_migration_content(migration_name, index_array)
      <<-EOM
* run `rails g migration #{migration_name}` and add the following content:


    class #{migration_name} < ActiveRecord::Migration
      def change
        #{index_array.sort.uniq.join("\n        ")}
      end
    end
EOM
    end
  end
end
