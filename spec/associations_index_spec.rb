require 'spec_helper'

RSpec.describe "Collect indexes based on associations:" do

  before :all do
    lol_dba = LolDba.check_for_indexes
    @relationship_indexes = lol_dba[0]
    @warning_messages = lol_dba[1].split("\n")
  end

  it "find relationship indexes" do
    expect(@relationship_indexes).not_to be_empty

    expect(@relationship_indexes).to have_key("companies")
    expect(@relationship_indexes).to have_key("companies_freelancers")
    expect(@relationship_indexes).to have_key("addresses")
    expect(@relationship_indexes).to have_key("purchases")
  end

  it "find indexes for belongs_to" do
    expect(@relationship_indexes["addresses"]).to include("country_id")
    expect(@relationship_indexes["favourites"]).to include("user_id")
  end

  it "find indexes for polymorphic belongs_to" do
    expect(@relationship_indexes["addresses"]).to include(["addressable_id", "addressable_type"])
  end

  it "find indexes for belongs_to with custom foreign key" do
    expect(@relationship_indexes["companies"]).to include("owner_id")
  end

  it "find indexes for has_and_belongs_to_many" do
    expect(@relationship_indexes["companies_freelancers"]).to include(["company_id", "freelancer_id"])
    expect(@relationship_indexes["companies_freelancers"]).not_to include(["freelancer_id", "company_id"])
  end

  it "find indexes for has_and_belongs_to_many with custom join_table, primary and foreign keys" do
    expect(@relationship_indexes["purchases"]).to include(["buyer_id", "present_id"])
  end

  it "find indexes for has_and_belongs_to_many but don't create the left_side index" do
    expect(@relationship_indexes["purchases"]).not_to include("left_side_id")
  end

  it "do not add an already existing index" do
    expect(@relationship_indexes["companies"]).not_to include("country_id")
  end

  it "find indexes for has_many :through" do
    expect(@relationship_indexes["billable_weeks"]).to include("remote_worker_id", "timesheet_id")
    expect(@relationship_indexes["billable_weeks"]).not_to include(["billable_week_id", "remote_worker_id"])
  end

  it "find indexes for has_many :through with source and foreign key" do
    expect(@relationship_indexes["complex_billable_week"]).to include(["freelancer_id", "id_complex_timesheet"])
  end

  it "do not include wrong class" do
    expect(@relationship_indexes["wrongs"]).to be_nil
    expect(@relationship_indexes["addresses_wrongs"]).to be_nil
  end

  it "have warnings(non-existent table) on test data" do
    expected_warnings = [
      "BUG: table 'wrongs' does not exist, please report this bug.",
      "BUG: table 'addresses_wrongs' does not exist, please report this bug."
    ]
    expect(@warning_messages).to match_array(expected_warnings)
  end

  it "find indexes for STI" do
    expect(@relationship_indexes["users"]).to include(["id", "type"])
  end

  it "find indexes for STI with custom inheritance column" do
    expect(@relationship_indexes["freelancers"]).to include(["id", "worker_type"])
  end

  it "finds the right join table for HABTM for an STI subclass" do
    expect(@relationship_indexes).not_to have_key('companies_worker_users')
    expect(@relationship_indexes).to have_key('companies_users')
    expect(@relationship_indexes["companies_users"]).to include(["company_id", "user_id"])
  end

  it "find indexes, than use custom class name option in association" do
    expect(@relationship_indexes["employers_freelancers"]).to be_nil
    expect(@relationship_indexes["companies_freelancers"]).to include(["company_id", "freelancer_id"])
    expect(@relationship_indexes["companies_freelancers"]).not_to include(["freelancer_id", "company_id"])
  end

  it "create index for HABTM with polymorphic relationship" do
    expect(@relationship_indexes["favourites"]).to include(["favourable_id", "favourable_type"])
    expect(@relationship_indexes["favourites"]).not_to include(["project_id", "user_id"])
    expect(@relationship_indexes["favourites"]).not_to include(["project_id", "worker_user_id"])
  end
end
