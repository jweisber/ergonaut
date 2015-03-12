class AddDecisionToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :decision, :string
  end
end
