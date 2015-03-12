class AddColumnDecisionEnteredAtToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :decision_entered_at, :datetime
  end
end
