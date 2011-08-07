class BillableWeek < ActiveRecord::Base
  
  belongs_to :freelancer
  belongs_to :timesheet

end