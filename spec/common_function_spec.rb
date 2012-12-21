require 'spec_helper'

describe "Function form_migration_content:" do

  before do
    @add = ["add_index :report, :_id_test_plan"]
  end

  it "print migration skeleton with set name" do
    #$stdout.should_receive(:puts).with(/TestMigration/i)
    migration = LolDba.form_migration_content("TestMigration", @add)
    migration.should =~ /class TestMigration/i
  end

  it "print migration with add_keys params" do
  #  $stdout.should_receive(:puts).with(/add_index :report, :_id_test_plan/i)
    migration = LolDba.form_migration_content("TestMigration", @add)
    migration.should =~ /add_index :report, :_id_test_plan/i
  end
end

describe "Function form_data_for_migration:" do

  it "return data for migrations for non-indexed single key in table" do
    relationship_indexes = {:users => [:user_id]}
    LolDba.stub(:key_exists?).with(:users, :user_id).and_return(false)

    add_indexes = LolDba.form_data_for_migration(relationship_indexes)

    add_indexes.first.should == "add_index :users, :user_id"
  end

  it "return data for migrations for non-indexed composite key in table" do
    relationship_indexes = {:friends => [[:user_id, :friend_id]]}
    LolDba.stub(:key_exists?).with(:friends, [:user_id, :friend_id]).and_return(false)

    add_indexes = LolDba.form_data_for_migration(relationship_indexes)

    add_indexes.first.should == "add_index :friends, [:user_id, :friend_id]"
  end

  it "ignore empty or nil keys for table" do
    relationship_indexes = {:table => [""], :table2 => [nil]}
    add_indexes = LolDba.form_data_for_migration(relationship_indexes)

    add_indexes.should be_empty
  end

end

describe "Function key_exists?:" do

  it "return true if key is already indexed" do
    LolDba.key_exists?("companies", "country_id").should be_true
  end

  it "return false if key is not indexed yet" do
    LolDba.key_exists?("addresses", "country_id").should be_false
  end

  it "return true if key is primary key(default)" do
    LolDba.key_exists?("addresses", "id").should be_true
  end

  it "return true if key is custom primary key" do
    LolDba.key_exists?("gifts", "custom_primary_key").should be_true
  end

end

describe "Function puts_migration_content:" do

  before do
    @relationship_indexes, warning_messages = LolDba.check_for_indexes
  end

  it "print migration code" do
    $stdout.should_receive(:puts).with("")
    $stdout.should_receive(:puts).with(/TIP/)
    $stdout.should_receive(:puts).with(/TestMigration/i)
    LolDba.puts_migration_content("TestMigration", @relationship_indexes, "")
  end

  it "print warning messages if they exist" do
    warning = "warning text here"
    $stdout.should_receive(:puts).at_least(:once).with(warning)
    $stdout.should_receive(:puts)

    LolDba.puts_migration_content("TestMigration", {}, warning)
  end

  it "print nothing if no indexes and warning messages exist" do
    $stdout.should_receive(:puts).with("")
    $stdout.should_receive(:puts).with("Yey, no missing indexes found!")
    LolDba.puts_migration_content("TestMigration",{}, "")
  end

end