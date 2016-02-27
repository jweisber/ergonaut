# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_digest        :string(255)
#  remember_token         :string(255)
#  managing_editor        :boolean
#  area_editor            :boolean
#  author                 :boolean
#  referee                :boolean
#  first_name             :string(255)
#  middle_name            :string(255)
#  last_name              :string(255)
#  affiliation            :string(255)
#  password_reset_token   :string(255)
#  password_reset_sent_at :datetime
#

class User < ActiveRecord::Base
  attr_accessor :query # for the referee search form in app/views/referee_assignment/new.html.erb
  fuzzily_searchable :full_name_affiliation_email

  has_secure_password
  has_many :submissions
  has_many :area_editor_assignments
  has_many :ae_submissions, through: :area_editor_assignments, source: :submission, inverse_of: :area_editor
  has_many :referee_assignments
  has_many :re_submissions, through: :referee_assignments, source: :submission

  after_initialize :set_defaults
  before_save { |user| user.email = email.downcase }
  before_save :new_remember_token

  validates :first_name, :last_name, presence: true
  validates :first_name, :last_name, :middle_name, length: { maximum: 50 }
  validates :email, presence:   true,
                    format:     { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_changed?
  validates :password_confirmation, presence: true, if: :password_changed?
  validates :gender, inclusion: { in: [ 'Female', 'Male', nil ],
      message: "must be Female, Male, or Unknown" }

  # validate just one role (except author == referee)
  validates :managing_editor, inclusion: { in: [true] }, if: '!area_editor? && !author?'
  validates :managing_editor, inclusion: { in: [false] }, if: 'area_editor? || author?'
  validates :area_editor, inclusion: { in: [true] }, if: '!managing_editor? && !author?'
  validates :area_editor, inclusion: { in: [false] }, if: 'managing_editor? || author?'
  validates :author, inclusion: { in: [true] }, if: '(!managing_editor? && !area_editor?) || referee?'
  validates :author, inclusion: { in: [false] }, if: 'managing_editor? || area_editor? || !referee?'
  validates :referee, inclusion: { in: [true] }, if: '(!managing_editor? && !area_editor?) || author?'
  validates :referee, inclusion: { in: [false] }, if: 'managing_editor? || area_editor? || !author?'


  # roles

  def role=(role)
    if role == 'Managing editor'
      self.managing_editor = true
      self.area_editor = self.author = self.referee = false
    elsif role == 'Area editor'
      self.area_editor = true
      self.managing_editor = self.author = self.referee = false
    elsif role == 'Author/referee'
      self.author = self.referee = true
      self.area_editor = self.managing_editor = false
    else
      return false
    end
    self.save
  end

  def role
    if self.managing_editor?
      "Managing editor"
    elsif self.area_editor?
      "Area editor"
    elsif self.author?
      "Author/referee"
    end
  end

  def self.roles
    ['Managing editor', 'Area editor', 'Author/referee']
  end

  def editor?
    self.managing_editor || self.area_editor
  end


  # queries

  def self.area_editors_ordered_by_last_name
    return User.order(:last_name).where(area_editor: true)
  end

  def self.referees_ordered_by_last_name
    User.order(:last_name).where(referee: true)
  end

  def self.map_area_editor_ids_to_completed_assignment_counts
    User.joins('LEFT OUTER JOIN area_editor_assignments ON users.id = area_editor_assignments.user_id')
    		.joins('LEFT OUTER JOIN submissions ON submissions.id = area_editor_assignments.submission_id')
    		.where(area_editor: true)
    		.where('submissions.decision_approved = ?', true)
    		.group('users.id')
    		.count('submissions.id')
  end

  def self.map_area_editor_ids_to_active_assignments_counts
    User.joins('LEFT OUTER JOIN area_editor_assignments ON users.id = area_editor_assignments.user_id')
    		.joins('LEFT OUTER JOIN submissions ON submissions.id = area_editor_assignments.submission_id')
    		.where(area_editor: true)
    		.where('submissions.decision_approved = ?', false)
        .where('submissions.withdrawn = ?', false)
    		.group('users.id')
    		.count('submissions.title')
  end

  def active_referee_assignments
    referee_assignments.where("(agreed = ? OR agreed IS NULL) AND (report_completed = ? OR report_completed IS NULL) "\
                              "AND (canceled = ? OR canceled IS NULL)", true, false, false)
  end

  def inactive_referee_assignments
    referee_assignments.where("agreed = ? OR report_completed = ? OR canceled = ?", false, true, true)
  end

  def active_submissions
    self.submissions.all.delete_if { |s| s.archived && !s.needs_revision? }
  end

  def inactive_submissions
    self.submissions.where(archived: true).delete_if { |s| s.needs_revision? }
  end

  def has_pending_referee_assignments?
    return false if self.editor?
    self.referee_assignments.each do |assignment|
      return true if assignment.awaiting_action?
    end
    false
  end


  # formatting

  def full_name
    full_name = "#{first_name} "
    full_name += "#{middle_name} " if self.middle_name && self.middle_name.length > 0
    full_name += "#{last_name}"
    full_name
  end

  def full_name_brackets_email
    full_name = "#{first_name} "
    full_name += "#{middle_name} " if self.middle_name && self.middle_name.length > 0
    full_name += "#{last_name}"
    full_name += " <#{email}>"
    full_name
  end

  def full_name_affiliation_email
    string = full_name
    string += " ("
    string += "#{affiliation}, " unless self.affiliation.blank?
    string += email
    string += ")"
  end

  def full_name_affiliation_email_changed?
    first_name_changed? ||
    middle_name_changed? ||
    last_name_changed? ||
    affiliation_changed? ||
    email_changed?
  end


  # creating & updating

  def create_another_user(params)
    new_user = User.new(self.permitted_params(params))

    unless self.managing_editor? && !new_user.password.blank?
      password = SecureRandom.urlsafe_base64(6)
      new_user.assign_attributes(password: password, password_confirmation: password)
    end

    NotificationMailer.notify_creator_registration(new_user, self, password).save_and_deliver if new_user.save

    return new_user
  end

  def permitted_params(params)
    if self.area_editor?
      params.permit(:first_name, :middle_name, :last_name, :affiliation, :email)
    elsif self.managing_editor?
      params.permit!
    else
      params.permit()
    end
  end


  # password resets

  def new_password_reset_token
    begin
      self.password_reset_token = SecureRandom.urlsafe_base64
    end while User.exists?(password_reset_token: self.password_reset_token)
  end

  def send_password_reset
    new_password_reset_token
    self.password_reset_sent_at = Time.current
    save!
    NotificationMailer.notify_password_reset(self).save_and_deliver
  end


  private

    def set_defaults
      self.managing_editor = false if self.managing_editor.nil?
      self.area_editor = false if self.area_editor.nil?
      self.referee = true if self.referee.nil?
      self.author = true if self.author.nil?
      new_remember_token if self.remember_token.nil?
      true
    end

    def new_remember_token
      self.remember_token = SecureRandom.urlsafe_base64 if self.changed?
    end

    def password_changed?
      self.password_digest.blank? || !self.password.blank? || !self.password_confirmation.blank?
    end
end
