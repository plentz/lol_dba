RSpec.describe LolDba::MigrationFormatter do
  describe '#migration_instructions' do
    subject(:formatter) { LolDba::MigrationFormatter.new('') }
    let(:index_to_add) { ['add_index :report, :_id_test_plan'] }

    it 'print migration skeleton with set name' do
      migration = formatter.migration_instructions(index_to_add)
      expect(migration).to match(/class AddMissingIndexes/i)
    end

    it 'print migration with add_keys params' do
      migration = formatter.migration_instructions(index_to_add)
      expect(migration).to match(/add_index :report, :_id_test_plan/i)
    end
  end

  describe '#format_for_migration' do
    subject(:formatter) { LolDba::MigrationFormatter.new('') }

    it 'return data for migrations for non-indexed single key in table' do
      relationship_indexes = { users: [:user_id] }

      add_indexes = formatter.format_for_migration(relationship_indexes)

      expect(add_indexes.first).to eq('add_index :users, :user_id')
    end

    it 'return data for migrations for non-indexed composite key in table' do
      relationship_indexes = { friends: [%i[user_id friend_id]] }

      add_indexes = formatter.format_for_migration(relationship_indexes)

      expect(add_indexes.first).to eq('add_index :friends, [:user_id, :friend_id]')
    end

    it 'ignore empty or nil keys for table' do
      relationship_indexes = { table: [''], table2: [nil] }
      add_indexes = formatter.format_for_migration(relationship_indexes)

      expect(add_indexes).to be_empty
    end
  end

  describe '#puts_migration_content' do
    before do
      @indexes = LolDba::IndexFinder.check_for_indexes
    end

    it 'print migration code' do
      expect($stdout).to receive(:puts).with(/AddMissingIndexes/i)
      LolDba::MigrationFormatter.new(@indexes).puts_migration_content
    end

    it 'print warning messages if they exist' do
      warning = 'warning text here'
      expect($stdout).to receive(:puts)

      LolDba::MigrationFormatter.new({}).puts_migration_content
    end

    it 'print nothing if no indexes and warning messages exist' do
      expect($stdout).to receive(:puts).with('Yey, no missing indexes found!')
      LolDba::MigrationFormatter.new({}).puts_migration_content
    end
  end
end
