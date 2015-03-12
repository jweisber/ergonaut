class AddAgreeAndDeclineCommentToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :agree, :boolean
    add_column :referee_assignments, :decline_comment, :text
  end
end
