class AddAreaIdToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :area_id, :integer
  end
end
