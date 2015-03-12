class AddAttachmentForEditorToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :attachment_for_editor, :string
  end
end
