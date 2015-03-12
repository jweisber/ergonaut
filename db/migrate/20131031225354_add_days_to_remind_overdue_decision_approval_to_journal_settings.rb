class AddDaysToRemindOverdueDecisionApprovalToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_to_remind_overdue_decision_approval, :integer
  end
end
