class AddAuthTokenToRefereeAssignments < ActiveRecord::Migration
  def change
    add_column :referee_assignments, :auth_token, :string
  end
end
