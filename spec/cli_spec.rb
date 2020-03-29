require 'lol_dba/cli'

RSpec.describe LolDba::CLI do
  subject do
    described_class.new('spec/fixtures', {})
  end

  describe '#start' do
    context 'with missing indexes' do
      before do
        allow(LolDba::IndexFinder).to receive(:run).and_return(true)
      end

      it 'returns false' do
        expect_any_instance_of(Kernel).to receive(:exit).with(1)
        subject.start('db:find_indexes')
      end
    end

    context 'without missing indexes' do
      before do
        allow(LolDba::IndexFinder).to receive(:run).and_return(false)
      end

      it 'returns true' do
        expect_any_instance_of(Kernel).not_to receive(:exit)
        subject.start('db:find_indexes')
      end
    end
  end
end
