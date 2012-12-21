class ComplexTimesheet < ActiveRecord::Base
  # Use for testing custom has_many :through

  has_many :complex_billable_weeks, :foreign_key => :id_complex_timesheet
  has_many :workers, :through => :complex_billable_weeks, :source => :slave

end