require 'spec_helper'
require 'lol_dba/sql_generator'

RSpec.describe "Sql Generator migrations:" do

  it "generates migrations without error" do
    expect { LolDba::SqlGenerator.generate('all') }.not_to raise_error
  end
end