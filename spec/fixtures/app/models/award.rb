class Award < ActiveRecord::Base
  has_and_belongs_to_many :donations
end
