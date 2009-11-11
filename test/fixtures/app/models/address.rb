class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  belongs_to :user
  belongs_to :company
end