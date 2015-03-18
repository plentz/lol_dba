require 'rubygems'
require 'rspec/core/rake_task'
require 'rdoc/task'
require "appraisal"

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  desc 'Default: run unit tests with appraisal.'
  task :default do
    sh "appraisal install && rake appraisal spec"
  end
else
  desc 'Default: run unit tests.'
  task :default => :spec
end

desc 'Testing the rails indexes plugin.'
RSpec::Core::RakeTask.new('spec')

desc 'Generate documentation for the lol_dba plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'LolDba'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
