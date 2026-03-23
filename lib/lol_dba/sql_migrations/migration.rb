module LolDba
  class Migration
    FILENAME_PATTERN = /^(\d+)_(.*)$/

    attr_reader :full_name, :writer

    def initialize(migration_file)
      @full_name = File.basename(migration_file, '.rb')
      @writer = LolDba::Writer.new("#{@full_name}.sql")
      require Rails.root.join(migration_file)
    end

    def number
      FILENAME_PATTERN.match(full_name)[1]
    end

    def name
      FILENAME_PATTERN.match(full_name)[2]
    end

    def to_s
      full_name
    end

    def migration_class
      name.camelize.split('.')[0].constantize
    end

    def up
      generate_instead_of_executing do
        migration_class.migrate(:up)
        connection.execute("INSERT INTO schema_migrations (version) VALUES (#{number})")
      end
    end

    def down
      generate_instead_of_executing do
        migration_class.migrate(:down)
        connection.execute("DELETE FROM schema_migrations WHERE version = #{number}")
      end
    end

    def connection
      ActiveRecord::Base.connection
    end

    def generate_instead_of_executing
      migration_mocker = LolDba::MigrationMocker.new(writer)

      migration_mocker.redefine_migration_methods
      yield
      migration_mocker.reset_methods
    end
  end
end
