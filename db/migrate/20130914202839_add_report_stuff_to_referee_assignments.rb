class AddReportStuffToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :recommendation_id, :integer
    add_column :referee_assignments, :comments_for_editor, :text
    add_column :referee_assignments, :comments_for_author, :text
    add_column :referee_assignments, :report_completed, :boolean
    add_column :referee_assignments, :report_completed_at, :datetime
    add_column :referee_assignments, :recommend_reject, :boolean
    add_column :referee_assignments, :recommend_major_revisions, :boolean
    add_column :referee_assignments, :recommend_minor_revisions, :boolean
    add_column :referee_assignments, :recommend_accept, :boolean
  end
end
