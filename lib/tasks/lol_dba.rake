require 'lol_dba'
require 'lol_dba/sql_generator'

namespace :db do
  desc "Display a migration for adding/removing all necessary indexes based on associations"
  task :find_indexes => :environment do
    LolDba.simple_migration
  end
  desc "Generate .sql files for your migrations inside db/migrate_sql folder"
  task :migrate_sql, [:which] => :environment do |t, args|
    args.with_defaults(:which => 'all')
    LolDba::SqlGenerator.generate(args[:which])
  end
  
end
