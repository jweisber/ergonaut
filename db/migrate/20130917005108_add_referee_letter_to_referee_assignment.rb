class AddRefereeLetterToRefereeAssignment < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :referee_letter, :string
  end
end
