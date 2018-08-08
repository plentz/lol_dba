RSpec.describe LolDba::SqlGenerator do
  before do
    FileUtils.mkdir_p(Pathname.new(Rails.root).join('db', 'migrate_sql'))
  end

  it 'generates migrations without error' do
    expect { LolDba::SqlGenerator.new('all').run }.not_to raise_error
  end
end
