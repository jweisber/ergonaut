class AddRevisionInfoToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :original_id, :integer
    add_column :submissions, :revision_number, :integer
  end
end
