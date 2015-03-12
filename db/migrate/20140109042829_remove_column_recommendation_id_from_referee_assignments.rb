class RemoveColumnRecommendationIdFromRefereeAssignments < ActiveRecord::Migration
  def up
    remove_column :referee_assignments, :recommendation_id
  end

  def down
    add_column :referee_assignments, :recommendation_id, :integer
  end
end
