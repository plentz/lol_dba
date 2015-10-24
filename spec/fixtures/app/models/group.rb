class Group < ActiveRecord::Base
  has_many :group_components
  has_many :components, through: :group_components
end
