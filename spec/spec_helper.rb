require 'bundler/setup'
require 'rails/all'
require 'active_record/railtie'
require 'lol_dba'
require 'simplecov'
require 'bigdecimal'
require 'pry'

ENV['RAILS_ENV'] ||= 'test'

SimpleCov.start

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

module Rails
  def self.root
    "#{Dir.pwd}/spec/fixtures"
  end
end
#binding.pry
Dir.glob("#{Rails.root}/app/models/*.rb").sort.each { |file| require_dependency file }
#require_dependency "#{__dir__}/fixtures/app/models/address.rb"

ActiveRecord::Schema.verbose = false
load 'fixtures/schema.rb'

#root_dir = File.dirname(__FILE__)

# add current dir to the load path
$LOAD_PATH.unshift('.')

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
    mocks.verify_partial_doubles = true
  end
end
