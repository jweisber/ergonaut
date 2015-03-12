class AddColumnResponseDueAtToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :response_due_at, :datetime
  end
end
