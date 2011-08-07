require 'spec_helper'

describe "Collect indexes based on AR::Base.find calls:" do
  
  before do
    @find_by_indexes, @warning_messages = RailsIndexes.ar_find_indexes(false)
  end
  
  it "not show indexes for primary keys" do
    @find_by_indexes["users"].should_not include("id")
    @find_by_indexes["gifts"].should_not include("custom_primary_key")
    @find_by_indexes["freelancers"].should_not include("id")
  end
  
  it "find_by indexes for self.find_by_email_and_name" do
    @find_by_indexes["users"].should include(["email", "name"])
    @find_by_indexes["users"].should include(["name", "email"])
  end
  
  it "find_by indexes for Gift.find_all_by_name_and_price" do
    @find_by_indexes["gifts"].should include(["name", "price"])
    @find_by_indexes["gifts"].should include(["price", "name"])
  end
  
  it "find_by indexes from UsersController" do
    @find_by_indexes["freelancers"].should include("name")
  end
  
  it "do not have warning on test data" do
    @warning_messages.should be_empty
  end
  
end