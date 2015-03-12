class AddIndexes < ActiveRecord::Migration
  def change
    add_index :submissions, :user_id
    add_index :submissions, :original_id
    add_index :submissions, :area_id
  end
end
