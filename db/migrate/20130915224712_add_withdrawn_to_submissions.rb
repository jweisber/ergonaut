class AddWithdrawnToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :withdrawn, :boolean
  end
end
