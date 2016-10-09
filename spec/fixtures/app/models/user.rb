class User < ActiveRecord::Base

  has_one :company, foreign_key: :owner_id
  has_one :address, as: :addressable

  has_and_belongs_to_many :users, join_table: :purchases, association_foreign_key: :present_id, foreign_key: :buyer_id

  has_many :projects
  has_many :favourites
  has_many :favourite_projects, through: :favourites, source: :favourable, source_type: 'Project'

  validates_uniqueness_of :name

end
