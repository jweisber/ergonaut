class AddEditorAreaRefToUsers < ActiveRecord::Migration
  def change
    add_column :users, :editor_area_id, :integer, references: :areas
    add_index :users, :editor_area_id
  end
end
