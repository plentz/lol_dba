require 'lol_dba'
require 'rails'

module LolDba
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/lol_dba.rake"
    end
  end
end