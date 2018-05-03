module LolDba
  class RailsCompatibility
    class << self
      def migrator
        ActiveRecord::Migrator.new(:up, migrations_path)
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
        if ar_version >= Gem::Version.new('5.2.0')
          ar_5_2_0_migrations_path
        elsif ar_version >= Gem::Version.new('5.0.0')
          ar_5_0_0_migrations_path
        elsif ar_version >= Gem::Version.new('4.0.0')
          ar_4_0_0_migrations_path
        else
          ActiveRecord::Migrator.migrations_path
        end
      end

      def ar_5_2_0_migrations_path
        paths = ActiveRecord::Migrator.migrations_paths
        ActiveRecord::MigrationContext.new(paths).migrations
      end

      def ar_5_0_0_migrations_path
        paths = ActiveRecord::Migrator.migrations_paths
        ActiveRecord::Migrator.migrations(paths)
      end

      def ar_4_0_0_migrations_path
        path = ActiveRecord::Migrator.migrations_path
        ActiveRecord::Migrator.migrations(path)
      end
    end
  end
end
