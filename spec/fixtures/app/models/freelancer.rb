class Freelancer < ActiveRecord::Base

  self.inheritance_column = 'worker_type'
  # use for testing custom class_name FK
  has_and_belongs_to_many :employers, :class_name => "Company"

  has_many :billable_weeks, :foreign_key => :remote_worker_id
  has_many :timesheets, :through => :billable_weeks

  # Use for testing custom has_many :through
  has_many :complex_billable_weeks
  has_many :complex_timesheets, :through => :complex_billable_weeks

end
