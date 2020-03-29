RSpec.describe LolDba::IndexFinder do
  describe '.run' do
    before do
      allow(described_class).to receive(:check_for_indexes).and_return(missing_indexes)
      allow_any_instance_of(LolDba::MigrationFormatter).to receive(:puts_migration_content)
    end

    context 'with missing indexes' do
      let(:missing_indexes) { { friends: [%i[user_id friend_id]] } }

      it 'returns false' do
        expect(described_class.run).to eq true
      end
    end

    context 'with missing indexes' do
      let(:missing_indexes) { {} }

      it 'returns true' do
        expect(described_class.run).to eq false
      end
    end
  end
end
