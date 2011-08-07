class Timesheet < ActiveRecord::Base
  
  has_many :billable_weeks
  has_many :freelancers, :through => :billable_weeks
  
end