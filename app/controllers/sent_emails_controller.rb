class SentEmailsController < ApplicationController
  before_filter :assigned_area_editor_or_managing_editor
  before_filter :associated_email, only: [:show]
  before_filter :bread_crumbs
  
  def index
    @submission = Submission.find(params[:submission_id]) if params[:submission_id]
    @submission = Submission.find(params[:archive_id]) if params[:archive_id]    
    @referee_assignment = RefereeAssignment.find(params[:referee_assignment_id]) if params[:referee_assignment_id]
    
    if @referee_assignment
      @emails = SentEmail.where(submission_id: @submission.id, referee_assignment_id: @referee_assignment.id).order('created_at DESC')
    else
      @emails = SentEmail.where(submission_id: @submission.id).order('created_at DESC')
      unless current_user.managing_editor?
        @emails.delete_if { |email| email.action == "notify_au_decision_reached" }
      end
    end
  end
  
  def show
    @submission = Submission.find(params[:submission_id]) if params[:submission_id]
    @submission = Submission.find(params[:archive_id]) if params[:archive_id]
    @email = SentEmail.find(params[:id])
  end
  
  private
  
    def assigned_area_editor_or_managing_editor
      unless managing_editor?
        if params[:submission_id] && current_user != Submission.find(params[:submission_id]).area_editor
          redirect_to security_breach_path
        end
      end
    end
    
    def associated_email
      if params[:submission_id]
        redirect_to security_breach_path unless SentEmail.find(params[:id]).submission == Submission.find(params[:submission_id])
      end
      if params[:referee_assignment_id]
        redirect_to security_breach_path unless SentEmail.find(params[:id]).referee_assignment == RefereeAssignment.find(params[:referee_assignment_id])
      end
    end
end
