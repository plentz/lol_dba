require 'spec_helper'

RSpec.describe 'Function form_migration_content:' do
  before do
    @add = ['add_index :report, :_id_test_plan']
  end

  it 'print migration skeleton with set name' do
    migration = LolDba::MigrationFormatter.form_migration_content('TestMigration', @add)
    expect(migration).to match(/class TestMigration/i)
  end

  it 'print migration with add_keys params' do
    migration = LolDba::MigrationFormatter.form_migration_content('TestMigration', @add)
    expect(migration).to match(/add_index :report, :_id_test_plan/i)
  end
end

RSpec.describe 'Function format_for_migration:' do
  it 'return data for migrations for non-indexed single key in table' do
    relationship_indexes = { users: [:user_id] }

    add_indexes = LolDba::MigrationFormatter.format_for_migration(relationship_indexes)

    expect(add_indexes.first).to eq('add_index :users, :user_id')
  end

  it 'return data for migrations for non-indexed composite key in table' do
    relationship_indexes = { friends: [%i[user_id friend_id]] }

    add_indexes = LolDba::MigrationFormatter.format_for_migration(relationship_indexes)

    expect(add_indexes.first).to eq('add_index :friends, [:user_id, :friend_id]')
  end

  it 'ignore empty or nil keys for table' do
    relationship_indexes = { table: [''], table2: [nil] }
    add_indexes = LolDba::MigrationFormatter.format_for_migration(relationship_indexes)

    expect(add_indexes).to be_empty
  end
end

RSpec.describe 'Function puts_migration_content:' do
  before do
    @relationship_indexes, warning_messages = LolDba.check_for_indexes
  end

  it 'print migration code' do
    expect($stdout).to receive(:puts).with('')
    expect($stdout).to receive(:puts).with(/TIP/)
    expect($stdout).to receive(:puts).with(/TestMigration/i)
    LolDba::MigrationFormatter.puts_migration_content('TestMigration', @relationship_indexes, '')
  end

  it 'print warning messages if they exist' do
    warning = 'warning text here'
    expect($stdout).to receive(:puts).at_least(:once).with(warning)
    expect($stdout).to receive(:puts)

    LolDba::MigrationFormatter.puts_migration_content('TestMigration', {}, warning)
  end

  it 'print nothing if no indexes and warning messages exist' do
    expect($stdout).to receive(:puts).with('')
    expect($stdout).to receive(:puts).with('Yey, no missing indexes found!')
    LolDba::MigrationFormatter.puts_migration_content('TestMigration', {}, '')
  end
end
