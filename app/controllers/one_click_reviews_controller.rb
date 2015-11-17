class OneClickReviewsController < ApplicationController

  skip_before_filter :signed_in_user
  before_filter :authorize, :bread_crumbs, :not_canceled
  before_filter :no_response_recorded, only: [:show, :agree, :decline]
  before_filter :declined, only: [:record_decline_comments]

  def show
    redirect_to edit_response_referee_center_path(@referee_assignment)
  end

  def agree
    if @referee_assignment.agree!
      flash[:success] = "Thanks for agreeing to perform this review! It's due #{@referee_assignment.date_due_pretty}"
      redirect_to edit_report_referee_center_path(@referee_assignment)
    else
      flash[:error] = 'Error: ' + @referee_assignment.errors.full_messages.join('; ')
      redirect_to edit_response_referee_center_path(@referee_assignment)
    end
  end

  def decline
    @submission = @referee_assignment.submission

    unless @referee_assignment.decline
      flash[:error] = 'Error: ' + @referee_assignment.errors.full_messages.join('; ')
      redirect_to referee_center_index_path
    end
  end

  def record_decline_comments
    decline_comment = params[:referee_assignment][:decline_comment]
    if @referee_assignment.update_attributes(decline_comment: decline_comment)
      NotificationMailer.notify_ae_or_me_decline_comment_entered(@referee_assignment).save_and_deliver unless decline_comment.blank?
      flash[:success] = "Thank you for your response."
      redirect_to referee_center_index_path
    else
      flash.now[:error] = "Something went wrong recording your response."
      render :decline
    end
  end

  private

    def authorize
      @referee_assignment = RefereeAssignment.find_by_auth_token(params[:id])

      if @referee_assignment
        sign_in @referee_assignment.referee
      else @referee_assignment
        flash[:error] = "I couldn't find a referee assignment for that URL."
        redirect_to security_breach_path
      end
    end

    def no_response_recorded
      @assignment = RefereeAssignment.find_by_auth_token(params[:id])
      if @assignment.agreed == true
        flash[:error] = "This request has already been accepted."
        redirect_to edit_report_referee_center_path(@assignment)
      elsif @assignment.agreed == false
        flash[:error] = "That request has already been declined."
        redirect_to referee_center_index_path
      end
    end

    def not_canceled
      @assignment = RefereeAssignment.find_by_auth_token(params[:id])
      if @assignment.canceled?
        flash[:error] = "That request was canceled."
        redirect_to referee_center_index_path
      end
    end

    def declined
      @assignment = RefereeAssignment.find_by_auth_token(params[:id])
      if @assignment.agreed.nil?
        flash[:error] = "This request hasn't been declined yet."
        redirect_to edit_response_referee_center_path(@assignment)
      elsif @assignment.agreed == true
        flash[:error] = "This request has already been accepted."
        redirect_to edit_report_referee_center_path(@assignment)
      end
    end
end
