module LolDba
  require 'lol_dba/sql_migrations/writer'
  require 'lol_dba/sql_migrations/migration'
  require 'lol_dba/sql_migrations/migration_mocker'
  require 'lol_dba/sql_migrations/sql_generator'
  require 'lol_dba/index_finding/migration_formatter'
  require 'lol_dba/index_finding/relation_inspector'
  require 'lol_dba/index_finding/index_finder'
  require 'lol_dba/index_finding/belongs_to'
  require 'lol_dba/index_finding/error_logging'
  require 'lol_dba/index_finding/has_and_belongs_to_many'
  require 'lol_dba/index_finding/has_many'
  require 'lol_dba/index_finding/relation_inspector_factory'
  require 'lol_dba/rails_compatibility'
  require 'lol_dba/railtie.rb' if defined?(Rails)
end
