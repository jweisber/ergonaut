class AddDaysBeforeDeadlineToRemindRefereeToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_before_deadline_to_remind_referee, :integer
  end
end
