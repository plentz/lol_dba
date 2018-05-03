require 'spec_helper'
require 'lol_dba/sql_generator'

RSpec.describe 'Sql Generator migrations:' do
  before do
    FileUtils.mkdir_p(Pathname.new(Rails.root).join('db', 'migrate_sql'))
  end

  it 'generates migrations without error' do
    expect { LolDba::SqlGenerator.generate('all') }.not_to raise_error
  end
end
