# -*- encoding: utf-8 -*-
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'rails_indexes/version.rb'

Gem::Specification.new do |s|
  s.name = "rails_indexes"
  s.version = RailsIndexes::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors =  "Elad Meidar"
  s.email =  "elad@eizesus.com"
  s.homepage = "http://blog.eizesus.com"
  s.summary = "A rake task to track down missing database indexes. does not assume that all foreign keys end with the convention of _id"
  s.description = "Rails indexes is a small package of 2 rake tasks that scan your application models and displays a list of columns that probably should be indexed."

  #s.rubyforge_project = "rails_indexes"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  
  s.add_dependency 'activerecord', '>=2.3.0'
  s.add_dependency 'actionpack'
  s.add_dependency 'railties'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'test-unit',  "~> 2.3.0"
end