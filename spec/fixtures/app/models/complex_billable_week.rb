class ComplexBillableWeek < ActiveRecord::Base
  # Use for testing custom has_many :through

  self.table_name = :complex_billable_week

  belongs_to :slave, :class_name => 'Freelancer'
  belongs_to :complex_timesheet, :foreign_key => :id_complex_timesheet

end