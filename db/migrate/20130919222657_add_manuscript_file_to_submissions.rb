class AddManuscriptFileToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :manuscript_file, :string
  end
end
