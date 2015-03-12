class CreateJournalSettings < ActiveRecord::Migration
  def change
    create_table :journal_settings do |t|
      t.integer :days_for_initial_review
      t.integer :days_to_respond_to_referee_request
      t.integer :days_to_remind_unanswered_invitation
      t.integer :days_for_external_review
      t.integer :days_to_remind_overdue_referee
      t.integer :days_for_initial_and_external_review
      t.string :journal_email

      t.timestamps
    end
  end
end
