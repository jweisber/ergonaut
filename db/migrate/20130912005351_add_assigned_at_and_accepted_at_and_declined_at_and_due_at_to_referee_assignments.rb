class AddAssignedAtAndAcceptedAtAndDeclinedAtAndDueAtToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :assigned_at, :datetime
    add_column :referee_assignments, :agreed_at, :datetime
    add_column :referee_assignments, :declined_at, :datetime
    add_column :referee_assignments, :due_at, :datetime
  end
end
