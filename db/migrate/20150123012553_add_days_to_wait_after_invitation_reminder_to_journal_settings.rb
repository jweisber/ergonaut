class AddDaysToWaitAfterInvitationReminderToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_to_wait_after_invitation_reminder, :integer
  end
end
