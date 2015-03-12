class RenameColumnDueAtInRefereeAssignments < ActiveRecord::Migration
  def up
    rename_column :referee_assignments, :due_at, :report_due_at
  end

  def down
    rename_column :referee_assignments, :report_due_at, :due_at
  end
end
