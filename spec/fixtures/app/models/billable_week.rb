class BillableWeek < ActiveRecord::Base

  belongs_to :remote_worker, :class_name => "Freelancer"
  belongs_to :timesheet

end