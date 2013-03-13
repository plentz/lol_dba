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
require 'fixtures/app/models/address.rb'
require 'fixtures/app/models/billable_week.rb'
require 'fixtures/app/models/company.rb'
require 'fixtures/app/models/complex_billable_week.rb'
require 'fixtures/app/models/complex_timesheet.rb'
require 'fixtures/app/models/country.rb'
require 'fixtures/app/models/freelancer.rb'
require 'fixtures/app/models/gift.rb'
require 'fixtures/app/models/god.rb'
require 'fixtures/app/models/timesheet.rb'
require 'fixtures/app/models/user.rb'
require 'fixtures/app/models/worker.rb'
require 'fixtures/app/models/worker_user.rb'
require 'fixtures/app/models/wrong.rb'
