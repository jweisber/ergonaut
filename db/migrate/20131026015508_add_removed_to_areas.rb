class AddRemovedToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :removed, :boolean
  end
end
