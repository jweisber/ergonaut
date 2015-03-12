class AddRoleBooleansToUser < ActiveRecord::Migration
  def change
    add_column :users, :managing_editor, :boolean
    add_column :users, :area_editor, :boolean
    add_column :users, :author, :boolean
    add_column :users, :referee, :boolean
  end
end
