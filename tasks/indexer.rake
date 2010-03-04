require File.join(File.dirname(__FILE__), "../lib/indexer.rb")

namespace :db do
  desc "collect indexes based on AR::Base.find calls."
  task :find_query_indexes => :environment do
    Indexer.ar_find_indexes
  end
  
  task :index_migration => :environment do
    Indexer.simple_migration
  end
end
