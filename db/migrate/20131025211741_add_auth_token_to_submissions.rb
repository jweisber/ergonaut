class AddAuthTokenToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :auth_token, :string
  end
end
