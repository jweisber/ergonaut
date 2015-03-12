class AddAttachmentForAuthorToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :attachment_for_author, :string
  end
end
