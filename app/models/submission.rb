# == Schema Information
#
# Table name: submissions
#
#  id                                        :integer          not null, primary key
#  title                                     :string(255)
#  user_id                                   :integer
#  created_at                                :datetime         not null
#  updated_at                                :datetime         not null
#  decision_approved                         :boolean
#  decision                                  :string(255)
#  archived                                  :boolean
#  withdrawn                                 :boolean
#  manuscript_file                           :string(255)
#  area_editor_comments_for_managing_editors :text
#  area_editor_comments_for_author           :text
#  area_id                                   :integer
#  original_id                               :integer
#  revision_number                           :integer
#  auth_token                                :string(255)
#  decision_entered_at                       :datetime
#


class Submission < ActiveRecord::Base
  include SubmissionStatusCheckers
  extend SubmissionFinders
  extend SubmissionReminders
  
  belongs_to :user
  belongs_to :author, class_name: "User", foreign_key: :user_id
  belongs_to :area
  belongs_to :original, class_name: 'Submission', foreign_key: :original_id
  has_many :revisions, class_name: 'Submission', foreign_key: :original_id
  has_one :area_editor_assignment
  has_one :area_editor, class_name: "User", through: :area_editor_assignment
  accepts_nested_attributes_for :area_editor  # needed for the nested form in SubmissionsController#edit
  has_many :referee_assignments
  has_many :referees, class_name: "User", through: :referee_assignments
  
  mount_uploader :manuscript_file, SubmissionUploader
  
  after_initialize :set_defaults, if: :new_record?
  before_validation :archive_if_decision_approved
  before_save :timestamp_decision_if_changed
  before_create :set_auth_token
  after_create :handle_creation
  around_update :send_emails

  validates :title, presence: true, length: { minimum: 1 }
  validates :user, presence: true
  validates :area, presence: true
  validates :revision_number, presence: true, numericality: true #, uniqueness: { scope: :original_id }
  validates :manuscript_file, presence: true, on: :create # why only on create?
  validate :manuscript_file_size
  validate :verify_archived_if_decision_approved
  validates_each :decision do |record, attribute, value|
    record.errors[:base] = "That's an impossible decision!" unless Decision.all.include? value 
  end
  
  
  # updaters

  def withdraw
    self.withdrawn = self.archived = true
    if self.save
      NotificationMailer.notify_ae_and_me_submission_withdrawn(self).save_and_deliver
      NotificationMailer.confirm_au_submission_withdrawn(self).save_and_deliver
      self.pending_referee_assignments.each do |assignment|
        NotificationMailer.notify_re_submission_withdrawn(assignment).save_and_deliver(same_thread: true)
      end
      self.referee_assignments.where(report_completed: true).each do |assignment|
        NotificationMailer.notify_re_submission_withdrawn(assignment).save_and_deliver(same_thread: true)
      end
      self
    else
      nil
    end
  end

  def unarchive(actor)
    self.archived = self.withdrawn = false
    self.decision_approved = false
    if self.save
      NotificationMailer.notify_me_and_ae_submission_unarchived(actor, self).save_and_deliver
      self
    else
      false
    end
  end
  
  def clear_manuscript_file_metadata
    `exiftool -all= -Title="Ergo Submission ##{self.id}" #{File.join(Rails.root.to_s, self.manuscript_file.to_s)}`
  end
  
  # queries

  def pending_referee_assignments
    self.referee_assignments.where("(agreed = ? OR agreed IS NULL)", true).where(canceled: false).where(report_completed: false)
  end

  def non_canceled_referee_assignments
    self.referee_assignments.where(canceled: false)
  end
  
  def non_canceled_non_declined_referee_assignments
    self.referee_assignments.where("(canceled = ? OR canceled IS NULL) AND (agreed = ? OR agreed IS NULL)", false, true)
  end

  
  # formatting
  
  def date_submitted_pretty
    self.created_at ? self.created_at.strftime("%b. %-d, %Y") : "\u2014"
  end
  
  
  # revisions & versions
  
  def latest_version_number
    self.original.revisions.maximum(:revision_number) || 0
  end

  def latest_version
    Submission.where(original_id: self.original.id).order(:id).last
  end
  
  def is_latest_version?
    self.revision_number == self.latest_version_number
  end
  
  def previous_versions
    Submission.where(original_id: self.original_id).where("revision_number < ?", self.revision_number)
  end

  def previous_revision
    Submission.where(original_id: self.original_id, revision_number: self.revision_number - 1).first
  end
  
  def previous_assignment(referee)
    return nil unless self.previous_revision
    
    assignments = self.previous_revision.referee_assignments.where(user_id: referee.id)
    assignments.each do |assignment|
      return assignment if assignment.report_completed
    end
    
    return nil
  end
  
  def needs_revision?
    self.decision_approved &&
    self.is_latest_version? &&
    (self.decision == Decision::MAJOR_REVISIONS || self.decision == Decision::MINOR_REVISIONS)
  end

  def submit_revision(params)
    revised_submission = Submission.new(title: self.title, author: self.author, area: self.area)
    revised_submission.area_editor_comments_for_managing_editors = nil
    revised_submission.area_editor_comments_for_author = nil
    revised_submission.update_attributes(params.permit(:title, :manuscript_file))
    revised_submission.original = self
    revised_submission.decision = Decision::NO_DECISION
    revised_submission.decision_approved = false
    revised_submission.revision_number = self.latest_version_number + 1
    revised_submission.archived = false
    self.archived = true
    
    begin
      self.transaction do
        revised_submission.save!
        self.save!
      end
    ensure
      return revised_submission
    end
  end
  
  
  # one-click
  
  def set_auth_token# create auth_token for one-click editing
    begin
      self.auth_token = SecureRandom.urlsafe_base64
    end while Submission.exists?(auth_token: self.auth_token)
  end
  

  private
  
    def set_defaults
      self.original = self if self.original.nil?
      self.revision_number ||= 0
      self.decision_approved = false if self.decision_approved.nil?
      self.decision ||= Decision::NO_DECISION
      self.archived = false if self.archived.nil?
      self.withdrawn = false if self.withdrawn.nil?
      return true
    end
    
    def manuscript_file_size
      return true unless self.manuscript_file.file
      if self.manuscript_file.file.size.to_f/(1000*1000) > 5.0
        errors.add(:file, "can't be larger than 5MB")
      end
    end
    
    def verify_archived_if_decision_approved
      puts "Validating!" unless !self.decision_approved || self.archived
      errors.add(:archived, "must be true if the decision is approved.") unless !self.decision_approved || self.archived
    end
    
    def handle_creation
      NotificationMailer.notify_me_new_submission(self).save_and_deliver
    end
    
    def archive_if_decision_approved
      self.archived = true if self.decision_approved?
    end
    
    def timestamp_decision_if_changed
      self.decision_entered_at = Time.current if self.decision_changed? && self.decision_was
    end
    
    def send_emails
      just_decided = self.decision_changed?
      just_approved_decision = self.decision_approved? && self.decision_approved_changed?
      
      yield
      
      if just_decided
        NotificationMailer.notify_me_decision_needs_approval(self).save_and_deliver
      end
      
      if just_approved_decision
        NotificationMailer.notify_au_decision_reached(self).save_and_deliver
        
        NotificationMailer.notify_ae_decision_approved(self).save_and_deliver if self.area_editor
        
        referees_already_thanked = Array.new
        self.referee_assignments.each do |assignment|
          if assignment.report_completed?
            referees_already_thanked.push assignment.referee.id
            NotificationMailer.notify_re_outcome(assignment).save_and_deliver 
          end
          assignment.cancel! if (assignment.awaiting_response? || assignment.awaiting_report?)
        end

        self.previous_versions.each do |version|
          version.referee_assignments.where(report_completed: true).each do |assignment|
            if referees_already_thanked.exclude? assignment.referee.id
              referees_already_thanked.push assignment.referee.id
              NotificationMailer.notify_re_outcome(assignment).save_and_deliver
            end
          end
        end

      end
    end
end