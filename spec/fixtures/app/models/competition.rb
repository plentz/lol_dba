class Competition < ActiveRecord::Base
  has_many :awards
  has_many :donations, through: :awards
end
