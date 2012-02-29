class ComplexBillableWeek < ActiveRecord::Base
  # Use for testing custom has_many :through

  set_table_name :complex_billable_week

  belongs_to :freelancer
  belongs_to :complex_timesheet, :foreign_key => :id_complex_timesheet

end