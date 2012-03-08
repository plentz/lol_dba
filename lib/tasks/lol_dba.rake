require 'lol_dba'
require 'lol_dba/sql_generator'

namespace :db do
  desc "Display a migration for adding/removing all necessary indexes based on associations"
  task :find_indexes => :environment do
    LolDba.simple_migration
  end
  desc "Generate .sql files for all your migrations inside db/migrate_sql folder"
  task :migrate_sql => :environment do
    LolDba::SqlGenerator.generate
  end
  
end
