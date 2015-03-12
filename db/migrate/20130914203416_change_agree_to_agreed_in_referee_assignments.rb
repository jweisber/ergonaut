class ChangeAgreeToAgreedInRefereeAssignments < ActiveRecord::Migration
  def change
     rename_column :referee_assignments, :agree, :agreed
   end
end
