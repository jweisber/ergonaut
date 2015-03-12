class AddShortNameToArea < ActiveRecord::Migration
  def change
    add_column :areas, :short_name, :string
  end
end
