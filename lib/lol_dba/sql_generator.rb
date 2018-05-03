module LolDba
  class SqlGenerator
    class << self
      def generate(which)
        generate_instead_of_executing do
          migrations(which).each { |file| up_and_down(file) }
        end
      end

      private

      def connection
        ActiveRecord::Base.connection
      end

      def methods_to_modify
        %i[execute do_execute rename_column change_column column_for tables indexes select_all] & connection.methods
      end

      def redefine_execution_methods
        save_original_methods
        redefine_execute_methods(:execute)
        # needed for activerecord-sqlserver-adapter
        redefine_execute_methods(:do_execute)

        connection.class.send(:define_method, :column_for) { |*args| args.last }
        connection.class.send(:define_method, :change_column) { |*_args| [] }
        connection.class.send(:define_method, :rename_column) { |*_args| [] }
        connection.class.send(:define_method, :tables) { |*_args| [] }
        connection.class.send(:define_method, :select_all) { |*_args| [] }
        connection.class.send(:define_method, :indexes) { |*_args| [] }
        # returns always the default(args[2])
        connection.class.send(:define_method, :index_name_exists?) { |*args| args[2] }
      end

      def redefine_execute_methods(name)
        connection.class.send(:define_method, name) do |*args|
          if args.first =~ /SELECT "schema_migrations"."version"/ || args.first =~ /^SHOW/
            orig_execute(*args)
          else
            Writer.write(to_sql(args.first, args.last))
          end
        end
      end

      def save_original_methods
        methods_to_modify.each do |method_name|
          connection.class.send(:alias_method, "orig_#{method_name}".to_sym, method_name)
        end
      end

      def reset_methods
        methods_to_modify.each do |method_name|
          begin
            connection.class.send(:alias_method, method_name, "orig_#{method_name}".to_sym)
          rescue StandardError
            nil
          end
        end
      end

      def generate_instead_of_executing
        LolDba::Writer.reset
        redefine_execution_methods
        yield
        reset_methods
      end

      def migrations(which)
        if which == 'all'
          migrator.migrations.collect(&:filename)
        elsif which == 'pending'
          pending_migrations
        else
          specific_migration(which)
        end
      end

      def pending_migrations
        pending = migrator.pending_migrations
        if pending.empty?
          puts 'No pending migrations.'
          exit
        end
        pending.collect(&:filename)
      end

      def specific_migration(which)
        migration = migrator.migrations.find { |m| m.version == which.to_i }
        if migration.present?
          [migration.filename]
        else
          puts "There are no migrations for version #{which}."
          exit
        end
      end

      def up_and_down(file)
        migration = LolDba::Migration.new(file)
        LolDba::Writer.file_name = "#{migration}.sql"
        migration.up
        # MigrationSqlGenerator::Writer.file_name = "#{migration}_down.sql"
        # migration.down
      end

      def migrator
        LolDba::RailsCompatibility.migrator
      end
    end
  end
end
