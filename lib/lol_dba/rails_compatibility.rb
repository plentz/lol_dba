module LolDba
  class RailsCompatibility
    class << self
      def migrator
        if ::ActiveRecord::VERSION::MAJOR >= 6
          ActiveRecord::Migrator.new(:up, migrations_path, ActiveRecord::SchemaMigration)
        else
          ActiveRecord::Migrator.new(:up, migrations_path)
        end
      end

      def tables
        if ::ActiveRecord::VERSION::MAJOR >= 5
          ActiveRecord::Base.connection.data_sources
        else
          ActiveRecord::Base.connection.tables
        end
      end

      private

      def migrations_path
        ar_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
        if ar_version >= Gem::Version.new('6')
          ar_6_migrations_path
        elsif ar_version >= Gem::Version.new('5.2')
          ar_5_2_migrations_path
        elsif ar_version >= Gem::Version.new('4')
          ar_4_migrations_path
        else
          path
        end
      end

      def ar_6_migrations_path
        ActiveRecord::MigrationContext.new(path, 6).migrations
      end

      def ar_5_2_migrations_path
        ActiveRecord::MigrationContext.new(path).migrations
      end

      def ar_4_migrations_path
        ActiveRecord::Migrator.migrations(path)
      end

      def path
        if ::ActiveRecord::VERSION::MAJOR >= 4
          ActiveRecord::Migrator.migrations_paths
        else
          ActiveRecord::Migrator.migrations_path
        end
      end
    end
  end
end
