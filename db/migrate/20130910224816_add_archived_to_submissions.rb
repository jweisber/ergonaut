class AddArchivedToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :archived, :boolean
  end
end
