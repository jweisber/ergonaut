class AddDaysToRemindAreaEditorToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_to_remind_area_editor, :integer
  end
end
