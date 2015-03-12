class AddDecisionApprovedToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :decision_approved, :boolean
  end
end
