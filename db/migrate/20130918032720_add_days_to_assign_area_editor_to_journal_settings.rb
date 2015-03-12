class AddDaysToAssignAreaEditorToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_to_assign_area_editor, :integer
  end
end
