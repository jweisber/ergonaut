# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150205191643) do

  create_table "area_editor_assignments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "submission_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "areas", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "short_name"
    t.boolean  "removed"
  end

  create_table "journal_settings", :force => true do |t|
    t.integer  "days_for_initial_review"
    t.integer  "days_to_respond_to_referee_request"
    t.integer  "days_to_remind_unanswered_invitation"
    t.integer  "days_for_external_review"
    t.integer  "days_to_remind_overdue_referee"
    t.string   "journal_email"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "days_to_remind_area_editor"
    t.integer  "days_to_assign_area_editor"
    t.integer  "days_before_deadline_to_remind_referee"
    t.integer  "number_of_reports_expected"
    t.integer  "days_to_remind_overdue_decision_approval"
    t.integer  "days_after_reports_completed_to_submit_decision"
    t.integer  "days_to_extend_missed_report_deadlines"
    t.integer  "days_to_wait_after_invitation_reminder"
  end

  create_table "referee_assignments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "submission_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.boolean  "agreed"
    t.text     "decline_comment"
    t.string   "auth_token"
    t.datetime "assigned_at"
    t.datetime "agreed_at"
    t.datetime "declined_at"
    t.datetime "report_due_at"
    t.boolean  "canceled"
    t.text     "comments_for_editor"
    t.text     "comments_for_author"
    t.boolean  "report_completed"
    t.datetime "report_completed_at"
    t.boolean  "recommend_reject"
    t.boolean  "recommend_major_revisions"
    t.boolean  "recommend_minor_revisions"
    t.boolean  "recommend_accept"
    t.string   "referee_letter"
    t.datetime "response_due_at"
    t.datetime "report_originally_due_at"
    t.string   "attachment_for_editor"
    t.string   "attachment_for_author"
  end

  create_table "sent_emails", :force => true do |t|
    t.integer  "submission_id"
    t.integer  "referee_assignment_id"
    t.string   "action"
    t.string   "subject"
    t.string   "to"
    t.string   "cc"
    t.text     "body"
    t.string   "attachments"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "submissions", :force => true do |t|
    t.string   "title"
    t.integer  "user_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "decision_approved"
    t.string   "decision"
    t.boolean  "archived"
    t.boolean  "withdrawn"
    t.string   "manuscript_file"
    t.text     "area_editor_comments_for_managing_editors"
    t.text     "area_editor_comments_for_author"
    t.integer  "area_id"
    t.integer  "original_id"
    t.integer  "revision_number"
    t.string   "auth_token"
    t.datetime "decision_entered_at"
  end

  add_index "submissions", ["area_id"], :name => "index_submissions_on_area_id"
  add_index "submissions", ["original_id"], :name => "index_submissions_on_original_id"
  add_index "submissions", ["user_id"], :name => "index_submissions_on_user_id"

  create_table "trigrams", :force => true do |t|
    t.string  "trigram",     :limit => 3
    t.integer "score",       :limit => 2
    t.integer "owner_id"
    t.string  "owner_type"
    t.string  "fuzzy_field"
  end

  add_index "trigrams", ["owner_id", "owner_type", "fuzzy_field", "trigram", "score"], :name => "index_for_match"
  add_index "trigrams", ["owner_id", "owner_type"], :name => "index_by_owner"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "managing_editor"
    t.boolean  "area_editor"
    t.boolean  "author"
    t.boolean  "referee"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "affiliation"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
  end

  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
