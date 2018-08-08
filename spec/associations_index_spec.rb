RSpec.describe 'Collect indexes based on associations:' do
  let (:indexes) { LolDba::IndexFinder.check_for_indexes }

  it 'find relationship indexes' do
    expect(indexes).not_to be_empty

    expect(indexes).to have_key('companies')
    expect(indexes).to have_key('companies_freelancers')
    expect(indexes).to have_key('addresses')
    expect(indexes).to have_key('purchases')
  end

  it 'find indexes for belongs_to' do
    expect(indexes['addresses']).to include('country_id')
    expect(indexes['favourites']).to include('user_id')
  end

  it 'find indexes for polymorphic belongs_to' do
    expect(indexes['addresses']).to include(%w[addressable_id addressable_type])
  end

  it 'find indexes for belongs_to with custom foreign key' do
    expect(indexes['companies']).to include('owner_id')
  end

  it 'find indexes for has_and_belongs_to_many' do
    expect(indexes['companies_freelancers']).to include(%w[company_id freelancer_id])
    expect(indexes['companies_freelancers']).not_to include(%w[freelancer_id company_id])
  end

  it 'find indexes for has_and_belongs_to_many with custom join_table, primary and foreign keys' do
    expect(indexes['purchases']).to include(%w[buyer_id present_id])
  end

  it "find indexes for has_and_belongs_to_many but don't create the left_side index" do
    expect(indexes['purchases']).not_to include('left_side_id')
  end

  it 'do not add an already existing index' do
    expect(indexes['companies']).not_to include('country_id')
  end

  it 'find indexes for has_many :through' do
    expect(indexes['billable_weeks']).to include('remote_worker_id', 'timesheet_id')
    expect(indexes['billable_weeks']).not_to include(%w[billable_week_id remote_worker_id])
  end

  it 'find indexes for has_many :through with source and foreign key' do
    expect(indexes['complex_billable_week']).to include(%w[freelancer_id id_complex_timesheet])
  end

  it 'do not include wrong class' do
    expect(indexes['wrongs']).to be_nil
    expect(indexes['addresses_wrongs']).to be_nil
  end

  it 'find indexes for STI' do
    expect(indexes['users']).to include(%w[id type])
  end

  it 'find indexes for STI with custom inheritance column' do
    expect(indexes['freelancers']).to include(%w[id worker_type])
  end

  it 'find indexes, than use custom class name option in association' do
    expect(indexes['employers_freelancers']).to be_nil
    expect(indexes['companies_freelancers']).to include(%w[company_id freelancer_id])
    expect(indexes['companies_freelancers']).not_to include(%w[freelancer_id company_id])
  end

  it 'create index for HABTM with polymorphic relationship' do
    expect(indexes['favourites']).to include(%w[favourable_id favourable_type])
    expect(indexes['favourites']).not_to include(%w[project_id user_id])
    expect(indexes['favourites']).not_to include(%w[project_id worker_user_id])
  end
end
