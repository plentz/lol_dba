# -*- encoding: utf-8 -*-
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'lol_dba/version.rb'

Gem::Specification.new do |s|
  s.name = "lol_dba"
  s.version = LolDba::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors =  ["Elad Meidar", "Vladimir Sharshov, ""Diego Plentz"]
  s.email =  ["elad@eizesus.com", "vsharshov@gmail.com", "diego@plentz.org"]
  s.homepage = "https://github.com/plentz/lol_dba"
  s.summary = "A rake task to track down missing database indexes. does not assume that all foreign keys end with the convention of _id"
  s.description = "Lol DBA is a small package of 2 rake tasks that scan your application models and displays a list of columns that probably should be indexed."

  #s.rubyforge_project = "lol_dba"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '>=2.3.0'
  s.add_dependency 'actionpack'
  s.add_dependency 'railties'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec'
end