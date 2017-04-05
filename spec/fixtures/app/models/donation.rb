class Donation < ActiveRecord::Base
  has_and_belongs_to_many :awards
end
