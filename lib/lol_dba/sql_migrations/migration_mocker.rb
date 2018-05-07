module LolDba
  class MigrationMocker
    def initialize(writer)
      @writer = writer
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

    def self.reset_methods
      methods_to_modify.each do |method_name|
        begin
          connection.class.send(:alias_method, method_name, "orig_#{method_name}".to_sym)
        rescue StandardError
          nil
        end
      end
    end

    private_class_method

    def self.connection
      ActiveRecord::Base.connection
    end

    def self.methods_to_modify
      %i[execute do_execute rename_column change_column column_for tables indexes select_all] & connection.methods
    end

    private

    def redefine_execute_methods(name)
      connection.class.send(:define_method, name) do |*args|
        if args.first =~ /SELECT "schema_migrations"."version"/ || args.first =~ /^SHOW/
          orig_execute(*args)
        else
          @writer.write(to_sql(args.first, args.last))
        end
      end
    end

    def save_original_methods
      methods_to_modify.each do |method_name|
        connection.class.send(:alias_method, "orig_#{method_name}".to_sym, method_name)
      end
    end
  end
end
