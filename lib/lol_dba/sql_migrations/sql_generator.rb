module LolDba
  class SqlGenerator
    class << self
      def generate(which)
        generate_instead_of_executing do
          migrations(which).each { |file| up_and_down(file) }
        end
      end

      private

      def generate_instead_of_executing
        LolDba::Writer.reset
        LolDba::MigrationMocker.redefine_execution_methods
        yield
        LolDba::MigrationMocker.reset_methods
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
