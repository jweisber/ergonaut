class AddHideReportFromAuthorToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :hide_report_from_author, :boolean
  end
end
