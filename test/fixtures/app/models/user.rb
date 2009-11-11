class User < ActiveRecord::Base
  belongs_to :company
  
  has_one :company, :foreign_key => 'owner_id'
  has_one :address, :as => :addressable 
  
end