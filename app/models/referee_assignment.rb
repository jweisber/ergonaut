# == Schema Information
#
# Table name: referee_assignments
#
#  id                        :integer          not null, primary key
#  user_id                   :integer
#  submission_id             :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  agreed                    :boolean
#  decline_comment           :text
#  auth_token                :string(255)
#  assigned_at               :datetime
#  agreed_at                 :datetime
#  declined_at               :datetime
#  report_due_at             :datetime
#  canceled                  :boolean
#  comments_for_editor       :text
#  attachment_for_editor     :string(255)
#  comments_for_author       :text
#  attachment_for_author     :string(255)
#  report_completed          :boolean
#  report_completed_at       :datetime
#  recommend_reject          :boolean
#  recommend_major_revisions :boolean
#  recommend_minor_revisions :boolean
#  recommend_accept          :boolean
#  referee_letter            :string(255)
#  response_due_at           :datetime
#


class RefereeAssignment < ActiveRecord::Base
  extend RefereeAssignmentReminders
  
  mount_uploader :attachment_for_editor, ReportAttachmentUploader
  mount_uploader :attachment_for_author, ReportAttachmentUploader
  
  belongs_to :referee, class_name: 'User', foreign_key: :user_id
  belongs_to :submission
  has_many :emails
  
  validates :referee, :submission, presence: true
  validate :recommendation_present, if: :report_completed
  validate :report_unchanged, if: :report_completed_previously?
  validate :agreed_unchanged, if: :agreed_or_declined_previously?
  validate :attachment_for_editor_size, :attachment_for_author_size  
  
  after_initialize :set_defaults, if: :new_record?
  before_save :handle_before_save
  before_create :handle_before_create
  after_create :handle_after_create  
  around_update :send_emails
  
  
  # virtual attributes
  
  def custom_email_opening
    @custom_email_opening
  end
  
  def custom_email_opening=(opening)
    @custom_email_opening = opening
  end
  
  def recommendation=(rec)
    if (rec == Decision::REJECT)
      self.recommend_reject = true; self.recommend_major_revisions = false; self.recommend_minor_revisions = false; self.recommend_accept = false
    elsif (rec == Decision::MAJOR_REVISIONS)
      self.recommend_major_revisions = true; self.recommend_reject = false; self.recommend_minor_revisions = false; self.recommend_accept = false
    elsif (rec == Decision::MINOR_REVISIONS)
      self.recommend_minor_revisions = true; self.recommend_reject = false; self.recommend_major_revisions = false; self.recommend_accept = false
    elsif (rec == Decision::ACCEPT)
      self.recommend_accept = true; self.recommend_reject = false; self.recommend_major_revisions = false; self.recommend_minor_revisions = false
    end 
  end
  
  def recommendation
    if self.recommend_reject?
      return Decision::REJECT
    elsif self.recommend_major_revisions?
      return Decision::MAJOR_REVISIONS
    elsif self.recommend_minor_revisions?
       return Decision::MINOR_REVISIONS
    elsif self.recommend_accept?
      return Decision::ACCEPT
    end 
  end
  
  
  # status checks
  
  def awaiting_response?
    self.agreed.nil? && !(self.canceled)
  end
  
  def response_overdue?
    return nil unless self.awaiting_response?    
    Time.current > self.response_due_at
  end
  
  def awaiting_report?
    self.agreed? &&
    !(self.report_completed?) &&
    !(self.canceled)
  end
  
  def awaiting_action?
    self.awaiting_response? || self.awaiting_report?
  end
  
  def report_overdue?
    return nil unless agreed?    
    Time.current > self.report_due_at
  end
  
  
  # finders

  scope :not_archived, -> { joins(:submission).where('submissions.archived = ?', false) }
  scope :no_response, -> { where(agreed: nil) }
  scope :agreed, -> { where(agreed: true) }
  scope :not_canceled, -> { where(self.arel_table[:canceled].not_eq(true)) }
  scope :not_completed, -> { where(self.arel_table[:report_completed].not_eq(true)) }
  scope :response_deadline_passed, -> { where('referee_assignments.response_due_at < ?', Time.current) }
  scope :overdue_reminder_date_passed, -> { where('referee_assignments.report_due_at < ?', Time.current - JournalSettings.days_to_remind_overdue_referee.days) }
  scope :early_reminder_due, -> { where('referee_assignments.report_due_at < ?',  Time.current + JournalSettings.days_before_deadline_to_remind_referee.days) }
  scope :no_email_with_action, ->(action) { where('referee_assignments.id NOT IN (SELECT referee_assignment_id FROM sent_emails WHERE action = ?)', action) }
  scope :reminder_unanswered, -> { where('referee_assignments.id IN (SELECT referee_assignment_id FROM sent_emails WHERE action = ? AND created_at < ?)', :remind_re_response_overdue, Time.current - JournalSettings.days_to_wait_after_invitation_reminder.days) }
  
  def self.overdue_response_reminder_needed
    self.not_archived
        .no_response
        .not_canceled
        .response_deadline_passed
        .no_email_with_action(:remind_re_response_overdue)
        .group('referee_assignments.id')
  end

  def self.unanswered_reminder_notification_needed
    self.not_archived
        .no_response
        .not_canceled
        .reminder_unanswered
        .no_email_with_action(:notify_ae_response_reminder_unanswered)
        .group('referee_assignments.id')
  end
  
  def self.report_due_soon_reminder_needed
    self.not_archived
        .agreed
        .not_canceled
        .not_completed
        .early_reminder_due
        .no_email_with_action(:remind_re_report_due_soon)
        .group('referee_assignments.id')
  end
  
  def self.overdue_report
    self.agreed
        .not_canceled
        .not_completed
        .overdue_reminder_date_passed
        .group('referee_assignments.id')
  end

  
  # updaters
  
  def agree!
    self.agreed = true
    self.agreed_at = Time.current
    self.save
  end
  
  def decline
    self.agreed = false
    self.declined_at = Time.current
    self.save
  end
  
  def decline_with_comment(comment)
    self.decline_comment = comment
    self.decline
  end
    
  def declined?
    self.agreed == false
  end
  
  def cancel!
    self.canceled = true
    if self.save && !self.declined?
      NotificationMailer.cancel_referee_assignment(self).save_and_deliver unless self.declined?
    else
      false
    end
  end

  
  # formatters

  def date_assigned_pretty
    self.assigned_at ? self.assigned_at.strftime("%b. %-d, %Y") : "\u2014"
  end
  
  def date_agreed_pretty
    self.agreed_at ? self.agreed_at.strftime("%b. %-d, %Y") : "\u2014"
  end
  
  def date_declined_pretty
    self.declined_at ? self.declined_at.strftime("%b. %-d, %Y") : "\u2014"
  end
  
  def date_due_pretty
    self.report_due_at ? self.report_due_at.strftime("%b. %-d, %Y") : "\u2014"
  end
  
  def date_originally_due_pretty
    self.report_originally_due_at ? self.report_originally_due_at.strftime("%b. %-d, %Y") : "\u2014"
  end
  
  def date_completed_pretty
    self.report_completed_at ? self.report_completed_at.strftime("%b. %-d, %Y") : "\u2014"
  end


  private
  
    def agreed_or_declined_previously?
      persisted? && !RefereeAssignment.find(id).agreed.nil?
    end
  
    def agreed_unchanged
      return true unless agreed_changed?
      if agreed_was
        errors[:base] = "this assignment has already been accepted."
      else
        errors[:base] = "this assignment has already been declined."
      end
    end
    
    def attachment_for_editor_size
      return true unless self.attachment_for_editor.file
      if self.attachment_for_editor.file.size.to_f/(1000*1000) > 5.0
        errors.add(:file, "can't be larger than 5MB")
      end
    end
    
    def attachment_for_author_size
      return true unless self.attachment_for_author.file
      if self.attachment_for_author.file.size.to_f/(1000*1000) > 5.0
        errors.add(:file, "can't be larger than 5MB")
      end
    end
    
    def recommendation_present
      errors.add(:recommendation, "required for a complete report") unless self.recommendation
    end
    
    def report_completed_previously?
      persisted? && RefereeAssignment.find(id).report_completed
    end
    
    def report_unchanged
      persisted_recommendation = RefereeAssignment.find(self.id).recommendation
      errors.add(:recommendation, "cannot be changed once report is completed") unless self.recommendation == persisted_recommendation
      errors.add(:comments_for_editor, "cannot be changed once report is complete.") if self.comments_for_editor_changed?
      errors.add(:comments_for_editor, "cannot be changed once report is complete.") if self.comments_for_author_changed?
      errors.add(:attachment_for_editor, "cannot be changed once report is complete.") if self.attachment_for_editor_changed?
      errors.add(:attachment_for_author, "cannot be changed once report is complete.") if self.attachment_for_author_changed?
    end
    
    def set_defaults
      self.report_completed = false if self.report_completed.nil?
      self.recommend_reject = false if self.recommend_reject.nil?
      self.recommend_major_revisions = false if self.recommend_major_revisions.nil?
      self.recommend_minor_revisions = false if self.recommend_minor_revisions.nil?
      self.recommend_accept = false if self.recommend_accept.nil?
      self.canceled = false if self.canceled.nil?
    end
  
    def handle_before_save
      if self.report_completed? && self.report_completed_changed?
        self.report_completed_at = Time.current
      end
    end
    
    def handle_before_create
      self.assigned_at = Time.current
      self.response_due_at = Time.current + JournalSettings.days_to_respond_to_referee_request.days
      self.report_due_at = Time.current + JournalSettings.days_for_external_review.days
      self.report_originally_due_at = self.report_due_at
            
      self.referee_letter = (65 + self.submission.referee_assignments.size).chr   # 65.chr == 'A'

      begin
        self.auth_token = SecureRandom.urlsafe_base64
      end while RefereeAssignment.exists?(auth_token: self.auth_token)
    end

    def handle_after_create
      NotificationMailer.request_referee_report(self).save_and_deliver
    end

    def send_emails
      just_agreed = self.agreed? && self.agreed_changed?
      just_declined = self.agreed == false && self.agreed_changed?
      just_completed = self.report_completed? && self.report_completed_changed?
      
      yield
      
      if just_agreed
        NotificationMailer.confirm_assignment_agreed(self).save_and_deliver
        NotificationMailer.notify_ae_referee_assignment_agreed(self).save_and_deliver
      end
      
      if just_declined
        NotificationMailer.notify_ae_or_me_referee_request_declined(self).save_and_deliver
      end
      
      if just_completed
        NotificationMailer.notify_ae_report_completed(self).save_and_deliver
        NotificationMailer.re_thank_you(self).save_and_deliver
      end
    end  
end
