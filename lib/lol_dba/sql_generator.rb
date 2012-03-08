module LolDba
  class SqlGenerator
    class << self
    
      def connection
        ActiveRecord::Base.connection
      end

      def methods_to_modify
        [:execute, :do_execute, :rename_column, :change_column, :column_for, :tables, :indexes, :select_all] & connection.class.methods
      end
    
      def redefine_execute_methods
        save_original_methods
        connection.class.send(:define_method, :execute) {|*args| Writer.write(args.first) }
        connection.class.send(:define_method, :do_execute) {|*args| Writer.write(args.first) }
        connection.class.send(:define_method, :column_for) {|*args| args.last }
        connection.class.send(:define_method, :change_column) {|*args| [] }
        connection.class.send(:define_method, :rename_column) {|*args| [] }
        connection.class.send(:define_method, :tables) {|*args| [] }
        connection.class.send(:define_method, :select_all) {|*args| [] }
        connection.class.send(:define_method, :indexes) {|*args| [] }
      end

      def save_original_methods
        methods_to_modify.each do |method_name|
          connection.class.send(:alias_method, "orig_#{method_name}".to_sym, method_name)
        end
      end
        
      def reset_methods
        methods_to_modify.each do |method_name|
          connection.class.send(:alias_method, method_name, "orig_#{method_name}".to_sym)
        end
      end
    
      def generate_instead_of_executing(&block)
        LolDba::Writer.reset
        redefine_execute_methods
        yield
        reset_methods
      end
    
      def migrations
        Dir.glob(File.join(Rails.root, "db", "migrate", '*.rb'))
      end
        
      def generate
        generate_instead_of_executing { migrations.each{|file| up_and_down(file) } }
      end
    
      def up_and_down(file)
        #TODO support to migrations with change
        migration = LolDba::Migration.new(file)
        LolDba::Writer.file_name = "#{migration}.sql"
        migration.up
        #MigrationSqlGenerator::Writer.file_name = "#{migration}_down.sql"
        #migration.down
      end
    end
  end
end