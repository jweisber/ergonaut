class RenameColumnNumberOfRequiredReports < ActiveRecord::Migration
  def change
    rename_column :journal_settings, :number_of_required_reports, :number_of_reports_expected
  end
end
