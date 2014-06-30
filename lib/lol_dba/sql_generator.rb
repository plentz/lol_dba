module LolDba
  class SqlGenerator
    class << self
    
      def connection
        ActiveRecord::Base.connection
      end

      def methods_to_modify
        [:execute, :do_execute, :rename_column, :change_column, :column_for, :tables, :indexes, :select_all] & connection.methods
      end

      def redefine_execute_methods
        save_original_methods
        connection.class.send(:define_method, :execute) { |*args|
          if args.first =~ /SELECT "schema_migrations"."version"/ || args.first =~ /^SHOW/
            self.orig_execute(*args)
          else
            Writer.write(to_sql(args.first, args.last))
          end
        }
        connection.class.send(:define_method, :do_execute) { |*args|
          if args.first =~ /SELECT "schema_migrations"."version"/ || args.first =~ /^SHOW/
             self.orig_do_execute(*args)
          else
            Writer.write(to_sql(args.first, args.last))
          end
        }
        connection.class.send(:define_method, :column_for) { |*args| args.last }
        connection.class.send(:define_method, :change_column) { |*args| [] }
        connection.class.send(:define_method, :rename_column) { |*args| [] }
        connection.class.send(:define_method, :tables) { |*args| [] }
        connection.class.send(:define_method, :select_all) { |*args| [] }
        connection.class.send(:define_method, :indexes) { |*args| [] }
        connection.class.send(:define_method, :index_name_exists?) { |*args| args[2] } #returns always the default(args[2])
      end

      def save_original_methods
        methods_to_modify.each do |method_name|
          connection.class.send(:alias_method, "orig_#{method_name}".to_sym, method_name)
        end
      end
        
      def reset_methods
        methods_to_modify.each do |method_name|
          connection.class.send(:alias_method, method_name, "orig_#{method_name}".to_sym) rescue nil
        end
      end
    
      def generate_instead_of_executing(&block)
        LolDba::Writer.reset
        redefine_execute_methods
        yield
        reset_methods
      end
    
      def migrations(which)
        migrator = nil
        if ActiveRecord.version.version =~ /^4./
          migrator = ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_path))
        else
          migrator = ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations_path)
        end
        if which == "all"
          migrator.migrations.collect { |m| m.filename }
        elsif which == "pending"
          pending = migrator.pending_migrations
          if pending.empty?
            puts "No pending migrations."
            exit
          end
          migrator.pending_migrations.collect { |m| m.filename }
        else
          if migration = migrator.migrations.find {|m| m.version == which.to_i}
            [migration.filename]
          else
            puts "There are no migrations for version #{which}."
            exit
          end
        end
      end
        
      def generate(which)
        generate_instead_of_executing { migrations(which).each { |file| up_and_down(file) } }
      end
    
      def up_and_down(file)
        migration = LolDba::Migration.new(file)
        LolDba::Writer.file_name = "#{migration}.sql"
        migration.up
        #MigrationSqlGenerator::Writer.file_name = "#{migration}_down.sql"
        #migration.down
      end
    end
  end
end