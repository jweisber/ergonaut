class AddNumberOfRequiredReportsToJournalSettings < ActiveRecord::Migration
  def change
    add_column :journal_settings, :number_of_required_reports, :integer
  end
end
