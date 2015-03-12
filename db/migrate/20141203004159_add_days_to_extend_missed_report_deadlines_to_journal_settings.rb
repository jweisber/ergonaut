class AddDaysToExtendMissedReportDeadlinesToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :days_to_extend_missed_report_deadlines, :integer
  end
end
