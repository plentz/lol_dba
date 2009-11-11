ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.column "company_id", :integer
    t.column "name",  :text
    t.column "email", :text
  end
  
  create_table "companies", :force => true do |t|
    t.column "name",  :text
    t.column "owned_id", :integer
  end
  
  create_table "addresses", :force => true do |t|
    t.column "addressable_type", :string
    t.column "addressable_id", :integer
    t.column "address", :text
  end
  
  create_table "freelancers", :force => true do |t|
    t.column "name", :string
    t.column "price_per_hour", :integer
  end
  
  create_table "companies_freelancers", :force => true do |t|
    t.column "freelancer_id", :integer
    t.column "company_id", :integer
  end
end