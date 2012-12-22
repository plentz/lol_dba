require 'spec_helper'

describe "Collect indexes based on associations:" do

  let!(:lol_dba){ LolDba.check_for_indexes }
  let(:relationship_indexes){ lol_dba[0] }
  let(:warning_messages){ lol_dba[1] }

  it "find relationship indexes" do
    relationship_indexes.should_not be_empty

    relationship_indexes.should have_key("companies")
    relationship_indexes.should have_key("companies_freelancers")
    relationship_indexes.should have_key("addresses")
    relationship_indexes.should have_key("purchases")
  end

  it "find indexes for belongs_to" do
    relationship_indexes["addresses"].should include("country_id")
  end

  it "find indexes for belongs_to with custom foreign key" do
    relationship_indexes["companies"].should include("owner_id")
  end

  it "find indexes for has_and_belongs_to_many" do
    relationship_indexes["companies_freelancers"].should include(["freelancer_id", "company_id"])
  end

  it "find indexes for has_and_belongs_to_many with custom join_table, primary and foreign keys" do
    relationship_indexes["purchases"].should include(["present_id", "buyer_id"])
  end

  it "do not add an already existing index" do
    relationship_indexes["companies"].should_not include("country_id")
  end

  it "find indexes for has_many :through" do
    relationship_indexes["billable_weeks"].should include(["remote_worker_id", "timesheet_id"])
  end

  it "find indexes for has_many :through with source and foreign key" do
    relationship_indexes["complex_billable_week"].should include(["freelancer_id", "id_complex_timesheet"])
  end

  it "do not include wrong class" do
    relationship_indexes["wrongs"].should be_nil
    relationship_indexes["addresses_wrongs"].should be_nil
  end

  it "have warnings(non-existent table) on test data" do
    warning_messages.should_not be_empty
    warning_messages.should =~ /\'wrongs\'/
    warning_messages.should =~ /\'addresses_wrongs\'/
  end

  it "find indexes for STI" do
    relationship_indexes["users"].should include(["id", "type"])
  end

  it "find indexes for STI with custom inheritance column" do
    relationship_indexes["freelancers"].should include(["id", "worker_type"])
  end

  it "find indexes, than use custom class name option in association" do
    relationship_indexes["employers_freelancers"].should be_nil
    relationship_indexes["companies_freelancers"].should include(["freelancer_id", "company_id"])
  end

end
