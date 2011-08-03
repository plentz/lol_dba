require 'rails_indexes'
require 'rails'

module RailsIndexes
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/rails_indexes.rake"
    end
  end
end