class CreateSentEmails < ActiveRecord::Migration
  def change
    create_table :sent_emails do |t|
      t.integer :submission_id
      t.integer :referee_assignment_id
      t.string :action
      t.string :subject
      t.string :to
      t.string :cc
      t.text :body
      t.string :attachments

      t.timestamps
    end
  end
end
