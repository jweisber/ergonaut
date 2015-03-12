# == Schema Information
#
# Table name: journal_settings
#
#  id                                               :integer, not null, primary key
#  days_for_initial_review                          :integer
#  days_to_respond_to_referee_request               :integer
#  days_to_remind_unanswered_invitation             :integer
#  days_for_external_review                         :integer
#  days_to_remind_overdue_referee                   :integer
#  journal_email                                    :string(255)
#  created_at                                       :datetime, not null
#  updated_at                                       :datetime, not null
#  days_to_remind_area_editor                       :integer
#  days_to_assign_area_editor                       :integer
#  days_before_deadline_to_remind_referee           :integer
#  number_of_reports_expected                       :integer
#  days_to_remind_overdue_decision_approval         :integer
#  days_after_reports_completed_to_submit_decision  :integer
#  days_to_extend_missed_report_deadlines           :integer

class JournalSettings < ActiveRecord::Base
  
  after_initialize :set_defaults, if: :new_record?
  
  validates :days_for_initial_review, 
            :days_to_remind_area_editor, 
            :days_for_external_review, 
            :days_to_respond_to_referee_request, 
            :days_to_remind_unanswered_invitation,
            :days_to_wait_after_invitation_reminder,
            :days_to_remind_overdue_referee,
            :days_before_deadline_to_remind_referee,
            :days_to_remind_overdue_decision_approval,
            :number_of_reports_expected,
            :days_after_reports_completed_to_submit_decision,
            :days_to_assign_area_editor,
            :days_to_extend_missed_report_deadlines,
            presence: true,
            numericality: true,
            inclusion: 0..1000
  validate :external_review_longer_than_early_reminder
  validates :journal_email, presence: true, format: { with: /^$|\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }

  def external_review_longer_than_early_reminder
    if self.days_for_external_review <= self.days_before_deadline_to_remind_referee
      errors.add(:base, "Days for external review must be more than the number of days before a deadline the referee is sent a reminder.")
    end
  end
  
  def self.current
    JournalSettings.first_or_create
  end
  
  def self.days_for_initial_review
    JournalSettings.current.days_for_initial_review
  end
  
  def self.days_to_remind_area_editor
    JournalSettings.current.days_to_remind_area_editor
  end
  
  def self.days_for_external_review
    JournalSettings.current.days_for_external_review
  end
  
  def self.days_to_respond_to_referee_request
    JournalSettings.current.days_to_respond_to_referee_request
  end
  
  def self.days_to_remind_unanswered_invitation
    JournalSettings.current.days_to_remind_unanswered_invitation
  end
  
  def self.days_to_wait_after_invitation_reminder
    JournalSettings.current.days_to_wait_after_invitation_reminder
  end
  
  def self.days_to_remind_overdue_referee
    JournalSettings.current.days_to_remind_overdue_referee
  end
  
  def self.days_before_deadline_to_remind_referee
    JournalSettings.current.days_before_deadline_to_remind_referee
  end
  
  def self.days_to_assign_area_editor
    JournalSettings.current.days_to_assign_area_editor
  end
  
  def self.days_after_reports_completed_to_submit_decision
    JournalSettings.current.days_after_reports_completed_to_submit_decision
  end
  
  def self.days_to_remind_overdue_decision_approval
    JournalSettings.current.days_to_remind_overdue_decision_approval
  end
  
  def self.number_of_reports_expected
    JournalSettings.current.number_of_reports_expected
  end
  
  def self.days_to_extend_missed_report_deadlines
    JournalSettings.current.days_to_extend_missed_report_deadlines
  end
  
  def self.journal_email
    JournalSettings.current.journal_email
  end
  
  private
  
    def set_defaults
      self.days_to_assign_area_editor ||= 2
      self.days_for_initial_review ||= 14
      self.days_to_remind_area_editor ||= 3
      self.days_for_external_review ||= 28
      self.days_to_respond_to_referee_request ||= 3
      self.days_to_remind_unanswered_invitation ||= 1
      self.days_to_wait_after_invitation_reminder ||= 1
      self.days_to_remind_overdue_referee ||= 1
      self.days_before_deadline_to_remind_referee ||= 7
      self.days_after_reports_completed_to_submit_decision ||= 5
      self.days_to_remind_overdue_decision_approval ||= 1
      self.number_of_reports_expected ||= 2
      self.days_to_extend_missed_report_deadlines ||= 7
      self.journal_email ||= "ergo.editors@gmail.com"
      return true
    end

end
