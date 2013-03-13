require 'active_record'
require 'active_support'
require 'action_controller'
require 'lol_dba'
require 'rspec/rails'

ENV["RAILS_ENV"] ||= 'test'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

class Rails
  def self.root
    "spec/fixtures"
  end
end

load 'fixtures/schema.rb'

root_dir = File.dirname(__FILE__)

# Load models
Dir["#{root_dir}/fixtures/app/models/**/*.rb"].each { |f| require f}

