require 'simplecov'

SimpleCov.adapters.define 'rails_indexes' do
  add_group 'Libraries', 'lib'
  
  add_filter 'spec'
end

SimpleCov.start 'rails_indexes' 

require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'active_support'
require 'action_controller'

require 'rails_indexes'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

class Rails
  def self.root
    "spec/fixtures"
  end
end

RSpec.configure do |config|
  # some (optional) config here
  #config.fixture_path = "spec/fixtures"
end

load 'fixtures/schema.rb'


root_dir = File.dirname(__FILE__)

# Load models
Dir["#{root_dir}/fixtures/app/models/**/*.rb"].each { |f| require f}

# load controllers
Dir["#{root_dir}/fixtures/app/controllers/**/*.rb"].each { |f| require f}

SimpleCov.at_exit do
  SimpleCov.result.format!
end