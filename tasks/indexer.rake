def check_for_indexes(migration_format = false)
  model_names = []
  Dir.chdir(Rails.root) do 
    model_names = Dir["**/app/models/*.rb"].collect {|filename| filename.split('/').last }.uniq
  end
  
  model_classes = []
  model_names.each do |model_name|
    class_name = model_name.sub(/\.rb$/,'').camelize
    begin
      klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
      if klass < ActiveRecord::Base && !klass.abstract_class?
        model_classes << klass
      end
    rescue
      # No-op
    end
  end
  puts "Found #{model_classes.size} Models"
  
  @indexes_required = Hash.new([])
  @index_migrations = Hash.new([])
  
  model_classes.each do |class_name|
    
  #  foreign_keys = []
    
    # check if this is an STI child instance
    if class_name.base_class.name != class_name.name
      # add the inharitance column on the parent table
      
      if !(migration_format)
        @indexes_required[class_name.base_class.table_name] += [class_name.base_class.inheritance_column].sort unless  @indexes_required[class_name.base_class.table_name].include?([class_name.base_class.inheritance_column].sort)
      else
        # index migration for STI should require both the primary key and the inheritance_column in a composite index.
        @index_migrations[class_name.base_class.table_name] += [[class_name.base_class.inheritance_column, class_name.base_class.primary_key].sort] unless @index_migrations[class_name.base_class.table_name].include?([class_name.base_class.inheritance_column].sort)
      end
    end
    
    class_name.reflections.each_pair do |reflection_name, reflection_options|
      case reflection_options.macro
      when :belongs_to
        # polymorphic?
        @table_name = class_name.table_name.to_s #(reflection_options.options.has_key?(:class_name) ?  reflection_options.options[:class_name].constantize.table_name : )
        if reflection_options.options.has_key?(:polymorphic) && (reflection_options.options[:polymorphic] == true)
          poly_type = "#{reflection_options.name.to_s}_type"
          poly_id = "#{reflection_options.name.to_s}_id"
          if !(migration_format)
            @indexes_required[@table_name.to_s] += [poly_type, poly_id].sort unless @indexes_required[@table_name.to_s].include?([poly_type, poly_id].sort)
          else
            
            @index_migrations[@table_name.to_s] += [[poly_type, poly_id].sort] unless @index_migrations[@table_name.to_s].include?([poly_type, poly_id].sort)
          end
        else
          
          foreign_key = reflection_options.options[:foreign_key] ||= reflection_options.primary_key_name

          if !(migration_format)
            @indexes_required[@table_name.to_s] += [foreign_key] unless @indexes_required[@table_name.to_s].include?(foreign_key)
          else
            @index_migrations[@table_name.to_s] += [foreign_key] unless @index_migrations[@table_name.to_s].include?(foreign_key)
          end
        end
      when :has_and_belongs_to_many
        table_name = reflection_options.options[:join_table] ||= [class_name.table_name, reflection_name.to_s].sort.join('_')
        association_foreign_key = reflection_options.options[:association_foreign_key] ||= "#{reflection_name.singularize}_id"
        foreign_key = reflection_options.options[:foreign_key] ||= "#{class_name.name.tableize.signularize}_id"
        
        if !(migration_format)
          @indexes_required[table_name.to_s] += [association_foreign_key, foreign_key].sort unless @indexes_required[table_name].include?([association_foreign_key, foreign_key].sort)
        else
          @index_migrations[table_name.to_s] += [[association_foreign_key, foreign_key].sort] unless @index_migrations[table_name].include?([association_foreign_key, foreign_key].sort)
        end
      else
        #nothing
      end
    end
  end

  @missing_indexes = {}
  @indexes_required.each do |table_name, foreign_keys|
    
    unless foreign_keys.blank?
      existing_indexes = ActiveRecord::Base.connection.indexes(table_name.to_sym).collect(&:columns).flatten
      keys_to_add = foreign_keys.uniq - existing_indexes
      @missing_indexes[table_name] = keys_to_add unless keys_to_add.empty?
    end
  end
  if !(migration_format)
    @missing_indexes
  else
    @index_migrations
  end
end

namespace :db do
  desc "scan for possible required indexes"
  task :show_me_some_indexes => :environment do
    
    check_for_indexes.each do |table_name, keys_to_add|
      puts "Table '#{table_name}' => #{keys_to_add.to_sentence}"
    end
  end
  
  task :show_me_a_migration => :environment do
    migration_format = true
    missing_indexes = check_for_indexes(migration_format)

    unless missing_indexes.keys.empty?
      add = []
      remove = []
      missing_indexes.each do |table_name, keys_to_add|
        keys_to_add.each do |key|
          next if key.blank?
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
      
      migration = <<EOM
class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    #{add.join("\n    ")}
  end
  
  def self.down
    #{remove.join("\n    ")}
  end
end
EOM

      puts "## Drop this into a file in db/migrate ##"
      puts migration
    end
  end
end
