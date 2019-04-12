module LolDba
  class MigrationMocker
    def initialize(writer)
      @writer = writer
    end

    def redefine_migration_methods
      save_original_methods
      redefine_metadata_methods
      redefine_execute_methods(:execute)
      # needed for activerecord-sqlserver-adapter
      redefine_execute_methods(:do_execute)
    end

    def reset_methods
      methods_to_modify.each do |method_name|
        begin
          connection_class.send(:alias_method, method_name, "orig_#{method_name}".to_sym)
        rescue StandardError
          nil
        end
      end
    end

    private_class_method

    def self.connection
      ActiveRecord::Base.connection
    end

    def redefine_connection_method(method, &block)
      self.class.connection.class.send(:define_method, method, block)
    end

    def methods_to_modify
      %i[execute do_execute rename_column change_column column_for tables indexes select_all] & self.class.connection.methods
    end

    private

    def save_original_methods
      methods_to_modify.each do |method_name|
        orig_name = "orig_#{method_name}".to_sym
        self.class.connection.class.send(:alias_method, orig_name, method_name)
      end
    end

    def redefine_metadata_methods
      redefine_connection_method(:column_for) { |*args| args.last }
      redefine_connection_method(:change_column) { |*_args| [] }
      redefine_connection_method(:rename_column) { |*_args| [] }
      redefine_connection_method(:tables) { |*_args| [] }
      redefine_connection_method(:select_all) { |*_args| [] }
      redefine_connection_method(:indexes) { |*_args| [] }
      # returns always the default(args[2])
      redefine_connection_method(:index_name_exists?) { |*args| args[2] }
    end

    def redefine_execute_methods(name)
      writer = @writer

      redefine_connection_method(name) do |*args|
        query = args.first
        if query =~ /SELECT "schema_migrations"."version"/ || query =~ /^SHOW/
          orig_execute(*args)
        else
          writer.write(to_sql(query, args.last))
        end
      end
    end
  end
end
