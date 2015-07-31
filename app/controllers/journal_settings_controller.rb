class JournalSettingsController < ApplicationController

  before_filter :managing_editor
  before_filter :bread_crumbs

  def index
    @settings = JournalSettings.current
    redirect_to edit_journal_setting_path @settings
  end

  def edit
    @new_area = Area.new
    @settings = JournalSettings.current
    @templates = email_templates
    
    unless @settings
      @settings = JournalSettings.new
      unless @settings.save
        flash[:error] = "Error retrieving/initializing the journal's settings."
      end
    end
  end
  
  def show_email_template
    @action_name = params[:id]
    @template = email_templates[@action_name.to_sym]
    @body = File.read("app/views/notification_mailer/#{@action_name}.text.erb")
  end

  def update
    @settings = JournalSettings.current
    if @settings.update_attributes(params[:journal_settings].permit!)
      flash.now[:success] = "Settings saved."
    else
      flash.now[:error] = "Failed to save settings."
    end
    
    @new_area = Area.new
    @templates = email_templates
    render :edit
  end
  
  def create_area
    @new_area = Area.new(params[:area].permit(:name, :short_name))
    old_area = Area.where(name: @new_area.name).first
    
    if old_area
      if old_area.update_attributes(removed: false)
        flash.now[:success] = "Area restored: #{old_area.name}."
      else
        flash.now[:error] = "Couldn't restore pre-existing area: #{old_area.name}."
      end
    else
      if @new_area.save
        flash.now[:success] = "Area created: #{params[:area][:name]}."
      else
        flash.now[:error] = "Couldn't create area: \"#{params[:area][:name]}\"."
      end
    end
    
    @settings = JournalSettings.current
    @templates = email_templates
    render :edit
  end
  
  def remove_area
    @area = Area.find(params[:remove_area][:area_id])
    @area.removed = true
    
    if @area.save
      flash[:success] = "Area removed."
    else
      flash.now[:error] = "Failed to remove the area: #{Area.find(params[:id])}."
    end
    
    @new_area = Area.new
    @settings = JournalSettings.current
    @templates = email_templates
    render :edit
  end
  
  private
  
    def managing_editor
      unless current_user.managing_editor?
        redirect_to security_breach_path
      end
    end
    
    def email_templates
      {
        #
        # MANAGING EDITORS
        #
        
          notify_me_new_submission: {
            description:     'New Submission',
            to:              'Managing Editors',
            cc:              nil,
            subject:         'New Submission',
            attachments:     nil
          },
          
          remind_managing_editors_assignment_overdue: {
            description:     'Area Editor Assignment Overdue',
            to:              'Managing Editors',
            cc:              nil,
            subject:         'Reminder: Assignment Needed',
            attachments:     nil
          },
          
          notify_me_decision_needs_approval: {
            description:     'Decision Needs Approval',
            to:              'Managing Editors',
            cc:              'Area Editor',
            subject:         'Decision Needs Approval: Submission "#{@submission.title}"',
            attachments:     nil
          },

          remind_managing_editors_decision_approval_overdue: {
            description:     'Decision Approval Overdue',
            to:              'Managing Editors',
            cc:              nil,
            subject:         'Reminder: Decision Needs Approval',
            attachments:     nil
          },
          
          notify_me_and_ae_submission_unarchived: {
            description:     'Submission Unarchived',
            to:              'Managing Editors, Area Editor',
            cc:              nil,
            subject:         'Unarchived: "#{@submission.title}"',
            attachments:     nil
          },

          #
          # AREA EDITORS
          #

          notify_ae_new_assignment: {
            description:     'New Assignment',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'New Assignment: "#{@submission.title}"',
            attachments:     nil
          },
          
          notify_ae_and_me_submission_withdrawn: {
            description:     'Submission Withdrawn',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Submission Withdrawn: \"#{@submission.title}\"',
            attachments:     nil
          },
          
          notify_ae_assignment_canceled: {
            description:     'Area Editor Assignment Cancelled',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Assignment Canceled: "#{@submission.title}"',
            attachments:     nil
          },
          
          remind_ae_internal_review_overdue: {
            description:     'Internal Review Overdue',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Overdue Internal Review: "#{@submission.title}"',
            attachments:     nil
          },

          notify_ae_referee_assignment_agreed: {
            description:     'Referee Agreed',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Referee Agreed: #{@referee_assignment.referee.full_name}',
            attachments:     nil
          },
          
          notify_ae_or_me_referee_request_declined: {
            description:     'Referee Assignment Declined',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Referee Assignment Declined: #{@referee_assignment.referee.full_name}',
            attachments:     nil
          },
          
          notify_ae_or_me_decline_comment_entered: {
            description:     'Decline Comment Entered',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Comments from #{@referee_assignment.referee.full_name}',
            attachments:     nil
          },

          notify_ae_response_reminder_unanswered: {
            description:     'Notify: Referee Request Unanswered Despite Reminder',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Referee Request Still Unanswered: "#{@referee_assignment.referee.full_name}"',
            attachments:     nil
          },
          
          notify_ae_report_completed: {
            description:     'Referee Assignment Completed',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Referee Report Completed: "#{@submission.title}"',
            attachments:     'Comments for Editor'
          },

          notify_ae_enough_reports_complete: {
            description:     'Enough Referee Reports Complete',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Enough Reports Complete for "#{@submission.title}"',
            attachments:     nil
          },

          notify_ae_all_reports_complete: {
            description:     'All Referee Reports Complete',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'All Reports Complete for "#{@submission.title}"',
            attachments:     nil
          },

          remind_ae_decision_based_on_external_reviews_overdue: {
            description:     'Decision Overdue',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Overdue Decision: "#{@submission.title}"',
            attachments:     nil
          },
          
          notify_ae_decision_approved: {
            description:     'Decision Approved',
            to:              'Area Editor',
            cc:              'Managing Editors',
            subject:         'Decision Approved: "#{@submission.title}"',
            attachments:     nil
          },
          
          #
          # REFEREES
          #
          
          notify_creator_registration: {
            description:     'Notification of Registration',
            to:              'User',
            cc:              nil,
            subject:         "You've been registered with Ergo",
            attachments:     nil
          },
          
          request_referee_report: {
            description:     'Referee Request',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Referee Request: #{@referee_assignment.submission.title}',
            attachments:     'Manuscript'
          }, 

          remind_re_response_overdue: {
            description:     'Remind: Response to Referee Request Overdue',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Reminder to Respond',
            attachments:     nil
          },

          confirm_assignment_agreed: {
            description:     'Confirm: Referee Agreed',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Assignment Confirmation: #{@submission.title}',
            attachments:     nil
          },
          
          remind_re_report_due_soon: {
            description:     'Remind: Report Due Soon',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Early Reminder: Report Due #{@referee_assignment.date_due_pretty}',
            attachments:     nil
          },

          remind_re_report_overdue: {
            description:     'Remind: Report Overdue',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Overdue Report',
            attachments:     nil
          },

          notify_re_submission_withdrawn: {
            description:     'Submission Withdrawn',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Withdrawn Submission',
            attachments:     nil
          },

          cancel_referee_assignment: {
            description:     'Cancel Referee Assignment',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Cancelled Referee Request: #{@submission.title}',
            attachments:     nil
          },
          
          re_thank_you: {
            description:     'Thank Referee',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Thank you',
            attachments:     nil
          },

          notify_re_outcome: {
            description:     'Notify Referee of Outcome',
            to:              'Referee',
            cc:              'Area Editor, Managing Editors',
            subject:         'Outcome & Thank You',
            attachments:     'Referee Comments for Author'
          },
          
          #
          # AUTHORS
          #
          
          confirm_au_submission_withdrawn: {
            description:     'Submission Withdrawn',
            to:              'Author',
            cc:              'Area Editor, Managing Editors',
            subject:         'Confirmation: Submission Withdrawn',
            attachments:     nil
          },

          notify_au_decision_reached: {
            description:     'Notify: Decision Reached',
            to:              'Author',
            cc:              'Area Editor, Managing Editors',
            subject:         'Decision Regarding Submission: "#{@submission.title}"',
            attachments:     'Comments for Author'
          },
          
          #
          # ANYONE
          #
          
          notify_password_reset: {
            description:     'Password Reset',
            to:              'User',
            cc:              nil,
            subject:         'Password Reset',
            attachments:     nil
          }
        }
          
    end
end
