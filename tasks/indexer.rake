require File.join(File.dirname(__FILE__), "../lib/indexer.rb")

namespace :db do
  desc "collect indexes based on AR::Base.find calls."
  task :show_me_ar_find_indexes => :environment do
    Indexer.ar_find_indexes
  end
  
  desc "scan for possible required indexes"
  task :show_me_some_indexes => :environment do
    Indexer.index_list
  end
  
  task :show_me_a_migration => :environment do
    Indexer.simple_migration
  end
end
