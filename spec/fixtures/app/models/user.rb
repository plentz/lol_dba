class User < ActiveRecord::Base

  has_one :company, :foreign_key => 'owner_id'
  has_one :address, :as => :addressable

  has_and_belongs_to_many :users, :join_table => "purchases", :association_foreign_key => 'present_id', :foreign_key => 'buyer_id'

  validates_uniqueness_of :name

end
