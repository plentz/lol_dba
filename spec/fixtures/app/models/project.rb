class Project < ActiveRecord::Base

  belongs_to :user
  has_many :favourites, as: :favourable

end
