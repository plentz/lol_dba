#require 'bundler'
#Bundler::GemHelper.install_tasks

require 'rubygems'
require 'rspec/core/rake_task'
require 'rdoc/task'

desc 'Default: run unit tests.'
task :default => :spec

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
