class RefereeCenterController < ApplicationController

  before_filter :bread_crumbs
  before_filter :referee, only: [:index, :archives]
  before_filter :assigned_referee, except: [:index, :archives]
  before_filter :no_response_recorded, only: [:edit_response, :update_response]
  before_filter :agreed_but_not_completed, only: [:edit_report, :update_report]

  def index
    @referee_assignments = current_user.active_referee_assignments
  end

  def edit_response
    @assignment = RefereeAssignment.find(params[:id])
    @submission = @assignment.submission
  end

  def update_response
    if params[:referee_assignment][:agreed] == "true"
      if @assignment.agree!
        flash[:success] = "Thanks for agreeing to perform this review! It's due #{ @assignment.date_due_pretty }"
        redirect_to edit_report_referee_center_path(@assignment)
      else
        flash.now[:error] = "Something went wrong recording your response. Try again?"
        render :edit_response
      end
    elsif params[:referee_assignment][:agreed] == "false"
      if @assignment.decline_with_comment(params[:referee_assignment][:decline_comment])
        flash[:success] = "Thanks for letting us know!"
        redirect_to referee_center_index_path
      else
        flash.now[:error] = "Something went wrong recording your response. Try again?"
        render :edit_response
      end
    else
      flash.now[:error] = "Please select either agree or decline."
      render :edit_response
    end
  end

  def edit_report
    @assignment = RefereeAssignment.find(params[:id])
    @submission = @assignment.submission
  end

  def update_report
    @assignment = RefereeAssignment.find(params[:id])
    @submission = @assignment.submission

    permitted_params = params[:referee_assignment].permit(:comments_for_author,
                                                          :attachment_for_author,
                                                          :comments_for_editor,
                                                          :attachment_for_editor,
                                                          :recommendation)
    @assignment.assign_attributes(permitted_params)
    @assignment.report_completed = true

    if @assignment.save
      if @assignment.submission.referee_reports_complete?
        NotificationMailer.notify_ae_all_reports_complete(@assignment.submission)
                          .save_and_deliver
      elsif @assignment.submission.has_enough_reports?
        NotificationMailer.notify_ae_enough_reports_complete(@assignment.submission)
                          .save_and_deliver
      end
      flash[:success] = "Your report has been received, thanks!"
      redirect_to referee_center_index_path
    else
      flash.now[:error] = "Something went wrong submitting your report."
      render :edit_report
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

    def no_response_recorded
      @assignment = RefereeAssignment.find(params[:id])
      if @assignment.agreed == true
        flash[:error] = "This request has already been accepted."
        redirect_to edit_report_referee_center_path(@assignment)
      elsif @assignment.agreed == false
        flash[:error] = "That request has already been declined."
        redirect_to referee_center_index_path
      end
    end

    def agreed_but_not_completed
      @assignment = RefereeAssignment.find(params[:id])
      if @assignment.agreed.nil?
        flash[:alert] = "Please first indicate whether you accept this request."
        redirect_to edit_response_referee_center_path(@assignment)
      elsif @assignment.agreed == false
        flash[:error] = "That request was declined."
        redirect_to referee_center_index_path
      elsif @assignment.report_completed?
        flash[:error] = "This report has already been completed."
        redirect_to referee_center_path(@assignment)
      end
    end
end
