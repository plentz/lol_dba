require 'lol_dba'

namespace :db do
  desc 'Display a migration for adding/removing all necessary indexes based on associations'
  task find_indexes: :environment do
    LolDba::IndexFinder.run
  end
  desc 'Generate .sql files for your migrations inside db/migrate_sql folder'
  task :migrate_sql, [:which] => :environment do |_t, args|
    args.with_defaults(which: 'all')
    LolDba::SqlGenerator.new(args[:which]).run
  end
end
