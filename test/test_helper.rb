require 'rubygems'
require 'activerecord'
require 'active_record/fixtures'
require 'active_support'
require 'active_support/test_case'
require 'action_controller'

require 'indexer'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

load 'test/fixtures/schema.rb'

# Load models
Dir['test/fixtures/app/models/**/*.rb'].each { |f| require f }

# load controllers
Dir['test/fixtures/app/controllers/**/*.rb'].each { |f| require f }

puts "Done!"