class AddCanceledToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :canceled, :boolean
  end
end
