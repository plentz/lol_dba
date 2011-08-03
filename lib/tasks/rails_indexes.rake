require 'rails_indexes'

namespace :db do
  desc "Collect indexes based on AR::Base.find calls."
  task :find_query_indexes => :environment do
    RailsIndexes.ar_find_indexes
  end
  desc "Collect indexes based on associations"
  task :index_migration => :environment do
    RailsIndexes.simple_migration
  end
end
