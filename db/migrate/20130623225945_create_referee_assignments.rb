class CreateRefereeAssignments < ActiveRecord::Migration
  def change
    create_table :referee_assignments do |t|
      t.integer :user_id
      t.integer :submission_id

      t.timestamps
    end
  end
end
