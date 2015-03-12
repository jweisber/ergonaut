class AddAreaEditorCommentsToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :area_editor_comments_for_managing_editors, :text
    add_column :submissions, :area_editor_comments_for_author, :text
  end
end
