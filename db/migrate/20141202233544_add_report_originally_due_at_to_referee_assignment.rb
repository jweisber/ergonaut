class AddReportOriginallyDueAtToRefereeAssignment < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :report_originally_due_at, :datetime
  end
end
