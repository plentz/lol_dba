class Gift < ActiveRecord::Base

  self.primary_key = :custom_primary_key
  has_and_belongs_to_many :users, :join_table => "purchases", :association_foreign_key => 'buyer_id', :foreign_key => 'present_id'

end
