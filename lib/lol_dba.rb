module LolDba
  require 'lol_dba/writer'
  require 'lol_dba/migration'
  require 'lol_dba/migration_formatter'
  require 'lol_dba/index_finder'
  require 'lol_dba/rails_compatibility'
  require 'lol_dba/railtie.rb' if defined?(Rails)
end
