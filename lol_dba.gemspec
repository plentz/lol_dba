$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")
require "lol_dba/version.rb"

Gem::Specification.new do |s|
  s.name = "lol_dba"
  s.version = LolDba::VERSION
  s.platform = Gem::Platform::RUBY

  s.authors =  ["Diego Plentz", "Elad Meidar", "Eric Davis", "Muness Alrubaie", "Vladimir Sharshov"]
  s.email =  ["diego@plentz.org", "elad@eizesus.com", "", "vsharshov@gmail.com"]
  s.homepage = "https://github.com/plentz/lol_dba"
  s.summary = "A small package of rake tasks to track down missing database indexes and generate sql migration scripts"
  s.description = "lol_dba is a small package of rake tasks that scan your application models and displays a list of columns that probably should be indexed. Also, it can generate .sql migration scripts."
  s.license = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib", "lib/lol_dba"]

  s.required_ruby_version = ">= 2.0.0"
  s.add_dependency "activerecord", ">= 3.0", "< 5.0"
  s.add_dependency "actionpack", ">= 3.0", "< 5.0"
  s.add_dependency "railties", ">= 3.0", "< 5.0"

  s.add_development_dependency "appraisal", "~> 1.0"
  s.add_development_dependency "test-unit", "~> 3.0"
end
