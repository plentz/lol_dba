require 'rails/all'
require 'lol_dba'
require 'rspec/rails'

ENV["RAILS_ENV"] ||= 'test'

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ":memory:"
)

module Rails
  def self.root
    "spec/fixtures/"
  end
end
Dir.glob("#{Rails.root}/app/models/*.rb").sort.each { |file| require_dependency file }
load 'fixtures/schema.rb'

root_dir = File.dirname(__FILE__)

#add current dir to the load path
$:.unshift('.')
