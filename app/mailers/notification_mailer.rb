class NotificationMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper # for pluralize
  include AbstractController::Callbacks
  helper NotificationMailerHelper
  before_filter :set_action
  after_filter :set_submission, :set_referee_assignment
  after_filter :cc_editors

  default from: "\"Ergo Editors\" <#{JournalSettings.journal_email}>"

  class Mail::Message
    attr_accessor :action, :submission, :referee_assignment

    def save_and_deliver(options = {})
      if options[:same_thread] == true || Rails.env.test?
        self.deliver
        SentEmail.create_from_message(self)
      else
        Thread.new do
          SentEmail.create_from_message(self)
          self.deliver
          ActiveRecord::Base.connection.close
        end
      end
    end

    def body_text
      self.multipart? ? self.text_part.body.to_s : self.body.to_s
    end
  end

  #
  # MANAGING EDITORS
  #

  def notify_me_new_submission(submission)
    @submission = submission
    managing_editors = User.where(managing_editor: true)
    @recipients_list = name_list(managing_editors)

    message = mail(to: mailto_string(managing_editors),
                   cc: mailto_string([@submission.author]),
                   subject: 'New Submission')
  end

  def remind_managing_editors_assignment_overdue(submission)
    @submission = submission
    managing_editors = User.where(managing_editor: true)
    @recipients_list = name_list(managing_editors)

    message = mail(to: mailto_string(managing_editors), subject: "Reminder: Assignment Needed")
  end

  def notify_me_decision_needs_approval(submission)
    @submission = submission
    @area_editor = submission.area_editor
    recipients = User.where(managing_editor: true)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Decision Needs Approval: Submission \"#{@submission.title}\"")
  end

  def remind_managing_editors_decision_approval_overdue(submission)
    @submission = submission
    recipients = User.where(managing_editor: true)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Reminder: Decision Needs Approval')
  end

  def notify_me_and_ae_submission_unarchived(actor, submission)
    @actor = actor
    @submission = submission
    recipients = User.where(managing_editor: true)
    recipients.push(@submission.area_editor) if @submission.area_editor
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Unarchived: \"#{@submission.title}\"")
  end


  #
  # AREA EDITORS
  #

  def notify_ae_new_assignment(submission)
    @submission = submission
    recipients = [@submission.area_editor]
    @recipients_list = name_list(recipients)

    attach_manuscript(@submission)

    message = mail(to: mailto_string(recipients), subject: "New Assignment: \"#{@submission.title}\"")
  end

  def notify_ae_and_me_submission_withdrawn(submission)
    @submission = submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Submission Withdrawn: \"#{@submission.title}\"")
  end

  def notify_ae_assignment_canceled(submission, area_editor)
    @submission = submission
    recipients = [area_editor]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Assignment Canceled: \"#{@submission.title}\"")
  end

  def remind_ae_internal_review_overdue(submission)
    @submission = submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Overdue Internal Review: \"#{@submission.title}\"")
  end

  def notify_ae_or_me_referee_request_declined(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Referee Assignment Declined: #{@referee_assignment.referee.full_name}")
  end

  def notify_ae_or_me_decline_comment_entered(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Comments from #{@referee_assignment.referee.full_name}")
  end

  def notify_ae_response_reminder_unanswered(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Referee Request Still Unanswered: #{@referee_assignment.referee.full_name}")
  end

  def notify_ae_report_completed(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    add_attachments(@referee_assignment)

    message = mail(to: mailto_string(recipients), subject: "Referee Report Completed: \"#{@submission.title}\"")
  end

  def notify_ae_enough_reports_complete(submission)
    @submission = submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Enough Reports Complete for \"#{@submission.title}\"")
  end

  def notify_ae_all_reports_complete(submission)
    @submission = submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "All Reports Complete for \"#{@submission.title}\"")
  end

  def remind_ae_decision_based_on_external_reviews_overdue(submission)
    @submission = submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Overdue Decision: \"#{@submission.title}\"")
  end

  def notify_ae_decision_approved(submission)
    @submission = submission
    recipients = area_editor_or_else_managing_editors(@submission)
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Decision Approved: \"#{@submission.title}\"")
  end


  #
  # REFEREES
  #

  def notify_creator_registration(user, third_party, password)
    @login_url = signin_url
    @third_party = third_party
    @email = user.email
    @password = password
    recipients = [user]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'You\'ve been registered with Ergo')
  end

  def request_referee_report(referee_assignment)
    @referee_assignment = referee_assignment
    @area_editor = @referee_assignment.submission.area_editor
    @referee_assignment.auth_token ||= 'auth_token' # for previewing
    recipients = [@referee_assignment.referee]
    reply_to = "\"Ergo Editors\" <#{JournalSettings.journal_email}>"
    reply_to += ", \"#{@area_editor.full_name}\" <#{@area_editor.email}>" if @area_editor

    attach_manuscript(@referee_assignment.submission)

    message = mail(reply_to: reply_to, to: mailto_string(recipients), subject: "Referee Request: \"#{@referee_assignment.submission.title}\"")
  end

  def remind_re_response_overdue(referee_assignment)
    @referee_assignment = referee_assignment
    @area_editor = @referee_assignment.submission.area_editor
    recipients = [@referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Reminder to Respond')
  end

  def confirm_assignment_agreed(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    @area_editor = @submission.area_editor
    recipients = [@referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Assignment Confirmation: \"#{@submission.title}\"")
  end

  def remind_re_report_due_soon(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    @area_editor = @submission.area_editor
    recipients = [@referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Early Reminder: Report Due #{@referee_assignment.date_due_pretty}")
  end

  def remind_re_report_overdue(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    @area_editor = @submission.area_editor
    recipients = [@referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Overdue Report')
  end

  def notify_re_submission_withdrawn(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = referee_assignment.submission
    @area_editor = @submission.area_editor
    recipients = [referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Withdrawn Submission')
  end

  def cancel_referee_assignment(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = @referee_assignment.submission
    @area_editor = @submission.area_editor
    recipients = [referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: "Cancelled Referee Request: \"#{@submission.title}\"")
  end

  def re_thank_you(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = referee_assignment.submission
    @area_editor = @submission.area_editor
    recipients = [referee_assignment.referee]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Thank you')
  end

  def notify_re_outcome(referee_assignment)
    @referee_assignment = referee_assignment
    @submission = referee_assignment.submission.latest_version
    @reported_on_this_version = (@referee_assignment.submission.id == @submission.id)
    @area_editor = @submission.area_editor
    referee = referee_assignment.referee

    @humanize = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten']
    @other_completed_assignments = Array.new
    @submission.referee_assignments.each do |assignment|
      if assignment.report_completed && assignment.referee != referee
        @other_completed_assignments.push assignment
      end
    end

    recipients = [referee]
    @recipients_list = name_list(recipients)

    add_attachments_for_referee(@submission, @referee_assignment)

    message = mail(to: mailto_string(recipients), subject: 'Outcome & Thank You')
  end


  #
  # AUTHORS
  #

  def confirm_au_submission_withdrawn(submission)
    @submission = submission
    @area_editor = @submission.area_editor
    recipients = [submission.author]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Confirmation: Submission Withdrawn')
  end

  def notify_au_decision_reached(submission)
    @submission = submission
    recipients = [@submission.author]
    @recipients_list = name_list(recipients)

    add_attachments_for_author(@submission)

    message = mail(to: mailto_string(recipients), subject: "Decision Regarding Submission: \"#{@submission.title}\"")
  end


  #
  # ANYONE
  #

  def notify_password_reset(user)
    @user = user
    recipients = [user]
    @recipients_list = name_list(recipients)

    message = mail(to: mailto_string(recipients), subject: 'Password Reset')
  end


  private
    def set_action
      message.action = action_name
    end

    def set_submission
      if @submission
        message.submission = @submission
      elsif @referee_assignment
        message.submission = @referee_assignment.submission
      end
    end

    def set_referee_assignment
      message.referee_assignment = @referee_assignment
    end

    def mailto_string(users)
      string = String.new
      users.each do |user|
        string += ', ' if !string.blank?
        string += user.full_name + ' <' + user.email + '>'
      end
      string
    end

    def name_list(users)
      users_names = users.map {|u| u.full_name}
      users_names.to_sentence
    end

    def managing_editors
      User.where(managing_editor: true)
    end

    def area_editor_or_else_managing_editors(submission)
      submission.area_editor ? [submission.area_editor] : managing_editors
    end

    def attach_manuscript(submission)
      path = submission.manuscript_file.current_path
      ext = File.extname(path)
      attachments["Submission#{ext}"] = File.read(path) if File.exists?(path)
    end

    def add_attachments_for_author(submission)
      completed_assignments = submission.referee_assignments.where(report_completed: true)
      completed_assignments.each do |report|
        unless report.attachment_for_author.current_path.blank?
          attachment = report.attachment_for_author.current_path
          ext = File.extname(attachment)
          attachments["Referee #{report.referee_letter}#{ext}"] = File.read(attachment) if File.exists?(attachment)
        end
      end
    end

    def add_attachments_for_referee(submission, referee_assignment)
      completed_assignments = submission.referee_assignments.where(report_completed: true)
      completed_assignments.each do |report|
        unless report.attachment_for_author.current_path.blank? || report == referee_assignment
          attachment = report.attachment_for_author.current_path
          ext = File.extname(attachment)
          attachments["Referee #{report.referee_letter}#{ext}"] = File.read(attachment) if File.exists?(attachment)
        end
      end
    end

    def add_attachments(assignment)
      unless assignment.attachment_for_editor.current_path.blank?
        attachment = assignment.attachment_for_editor.current_path
        ext = File.extname(attachment)
        attachments["Attachment for Editor#{ext}"] = File.read(attachment) if File.exists?(attachment)
      end

      unless assignment.attachment_for_author.current_path.blank?
        attachment = assignment.attachment_for_author.current_path
        ext = File.extname(attachment)
        attachments["Attachment for Author#{ext}"] = File.read(attachment) if File.exists?(attachment)
      end
    end

    def cc_editors
      cc_managing_editors_actions = [
        'notify_ae_decision_approved',
        'notify_ae_new_assignment',
        'notify_ae_assignment_canceled',
        'notify_ae_or_me_referee_request_declined',
        'notify_ae_or_me_decline_comment_entered',
        'notify_ae_report_completed',
        'remind_ae_decision_based_on_external_reviews_overdue',
        'remind_ae_internal_review_overdue',
        'notify_ae_and_me_submission_withdrawn',
        'notify_ae_enough_reports_complete',
        'notify_ae_all_reports_complete',
        'request_referee_report',
        'remind_re_response_overdue',
        'notify_ae_response_reminder_unanswered',
        'confirm_assignment_agreed',
        'remind_re_report_due_soon',
        'remind_re_report_overdue',
        'cancel_referee_assignment',
        're_thank_you',
        'notify_re_submission_withdrawn',
        'notify_re_outcome',
        'notify_au_decision_reached',
        'confirm_au_submission_withdrawn'
      ]

      cc_area_editor_actions = [
        'notify_me_decision_needs_approval',
        'request_referee_report',
        'remind_re_response_overdue',
        'confirm_assignment_agreed',
        'remind_re_report_due_soon',
        'remind_re_report_overdue',
        'cancel_referee_assignment',
        're_thank_you',
        'notify_re_submission_withdrawn',
        'notify_re_outcome'
      ]

      message.cc = Mail::AddressContainer.new('cc') unless message.cc.present?

      if cc_managing_editors_actions.include? action_name
        message.cc << mailto_string(managing_editors)
      end

      if ((cc_area_editor_actions.include? action_name) && @area_editor)
        message.cc << mailto_string([@area_editor])
      end
    end

end
