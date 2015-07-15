class RefereeCenterController < ApplicationController
  
  before_filter :bread_crumbs
  before_filter :referee, only: [:index, :archives]
  before_filter :assigned_referee, except: [:index, :archives]
  
  def index
    @referee_assignments = current_user.active_referee_assignments
  end
  
  def edit
    @referee_assignment = RefereeAssignment.find(params[:id])
    @submission = @referee_assignment.submission
  end
  
  def update
    @referee_assignment = RefereeAssignment.find(params[:id])
    @submission = Submission.find(@referee_assignment.submission)
    
    # agreeing to review?
    if params[:referee_assignment][:agreed] == "true"
      if @referee_assignment.agree!
        flash[:success] = "Thanks for agreeing to perform this review! It's due #{ @referee_assignment.date_due_pretty }"
      else
        flash[:error] = "Something went wrong recording your response. Try again?"
      end
      redirect_to edit_referee_center_path(@referee_assignment)
    
    # declining to review?
    elsif params[:referee_assignment][:agreed] == "false"
      if @referee_assignment.decline_with_comment(params[:referee_assignment][:decline_comment])
        flash[:success] = "Thanks for letting us know!"
        redirect_to referee_center_index_path
      else
        flash[:error] = "Something went wrong recording your response. Try again?"
        redirect_to edit_referee_center_path(@referee_assignment)
      end
      
    # saving work?
    elsif params[:referee_assignment][:recommendation]
      @referee_assignment.update_attributes(params[:referee_assignment].permit(:comments_for_author,
                                                                               :attachment_for_author,
                                                                               :comments_for_editor,
                                                                               :attachment_for_editor,
                                                                               :recommendation))
      @referee_assignment.report_completed = true
      if @referee_assignment.save
        NotificationMailer.notify_ae_all_reports_complete(@referee_assignment.submission).save_and_deliver if @referee_assignment.submission.referee_reports_complete?
        flash[:success] = "Your report has been submitted, thanks!"
        redirect_to referee_center_index_path
      else
        flash[:error] = "Something went wrong submitting your report. Try again?"
        redirect_to preview_referee_center_path(@referee_assignment)
      end
  
    # being a careless user?
    else
      flash.now[:error] = "Please select either agree or decline."
      render :edit
    end
  end
  
  def preview
    @referee_assignment = RefereeAssignment.find(params[:id])
    @submission = @referee_assignment.submission
  end
  
  def complete
    @referee_assignment = RefereeAssignment.find(params[:id])
    if @referee_assignment.update_attributes(report_completed: true)
      flash[:success] = "Your report has been submitted, thanks!"
      redirect_to referee_center_index_path
    else
      flash[:error] = "Something went wrong submitting your report, sorry"
      redirect_to preview_referee_center_path(@referee_assignment)
    end
  end
  
  def archives
	  @referee_assignments = current_user.inactive_referee_assignments
  end
  
  def show
    @referee_assignment = RefereeAssignment.find(params[:id])
    @attachment_for_editor = @referee_assignment.attachment_for_editor if @referee_assignment.attachment_for_editor
    @attachment_for_author = @referee_assignment.attachment_for_author if @referee_assignment.attachment_for_author
    @submission = @referee_assignment.submission
  end
  
  private
    
    def referee
      redirect_to security_breach_path unless current_user.referee?
    end
    
    def assigned_referee
      @referee_assignment = RefereeAssignment.find(params[:id])
      redirect_to security_breach_path unless @referee_assignment && @referee_assignment.referee == current_user
    end
  
end
