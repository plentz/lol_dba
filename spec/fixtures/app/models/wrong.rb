class Wrong < ActiveRecord::Base
  # Class without table (wrong class), use for testing warning in Associations indexes

  belongs_to :user
  has_and_belongs_to_many :addresses

end
