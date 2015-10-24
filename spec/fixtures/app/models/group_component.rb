class GroupComponent < ActiveRecord::Base
  belongs_to :profile_group
  belongs_to :profile_component
end
