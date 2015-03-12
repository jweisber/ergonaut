class AddDaysAfterReportsCompletedToSubmitDecisionToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_after_reports_completed_to_submit_decision, :integer
  end
end
