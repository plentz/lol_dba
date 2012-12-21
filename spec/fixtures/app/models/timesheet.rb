class Timesheet < ActiveRecord::Base

  has_many :paiment_weeks, :class_name => "BillableWeek"
  has_many :remote_workers, :through => :paiment_weeks

end