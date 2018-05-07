module LolDba
  class SqlGenerator
    def initialize(which)
      @which = which
    end

    def run
      LolDba::Writer.reset_output_dir
      migrations(@which).each do |file|
        LolDba::Migration.new(file).up
      end
    end

    private

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

    def migrator
      LolDba::RailsCompatibility.migrator
    end
  end
end
