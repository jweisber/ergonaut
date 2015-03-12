class RemoveDaysForInitialAndExternalReviewFromJournalSettings < ActiveRecord::Migration
  def up
    remove_column :journal_settings, :days_for_initial_and_external_review
  end

  def down
    add_column :journal_settings, :days_for_initial_and_external_review, :integer
  end
end
