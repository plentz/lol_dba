require 'rake'
load './lib/tasks/lol_dba.rake'

RSpec.describe 'Tasks' do
  before do
    subject.clear_prerequisites
  end

  describe 'db:find_indexes' do
    subject { Rake::Task['db:find_indexes'] }

    context 'with missing indexes' do
      before do
        allow(LolDba::IndexFinder).to receive(:run).and_return(true)
      end

      it 'returns false' do
        expect_any_instance_of(Kernel).to receive(:exit).with(1)
        subject.invoke
      end
    end

    context 'without missing indexes' do
      before do
        allow(LolDba::IndexFinder).to receive(:run).and_return(false)
      end

      it 'returns true' do
        expect_any_instance_of(Kernel).not_to receive(:exit)
        subject.invoke
      end
    end
  end
end
