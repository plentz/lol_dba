class Component < ActiveRecord::Base
  has_many :groups, through: :group_components
end
