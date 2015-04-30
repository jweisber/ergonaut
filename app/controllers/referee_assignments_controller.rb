class RefereeAssignmentsController < ApplicationController
  
  before_filter :assigned_area_editor_or_managing_editor, only: [:new, :select_existing_user, :register_new_user, :create, :agree_on_behalf, :decline_on_behalf, :destroy]
  before_filter :author_or_assigned_referee_or_assigned_area_editor_or_managing_editor, only: [:show, :edit, :update, :download_attachment_for_editor, :download_attachment_for_author]
  before_filter :bread_crumbs
  
  def new
    @submission = Submission.find(params[:submission_id])
    @available_referees = User.referees_ordered_by_last_name # in case assigning an existing user
    @new_user = User.new    # in case assigning a new user
  end
  
  def select_existing_user
    @submission = Submission.find(params[:submission_id])
    
    if params[:user][:id].blank?
      query = params[:user][:query]
      @referee = User.find_by_fuzzy_full_name_affiliation_email(query, limit: 1).first
      unless @referee
        flash.now[:error] = "I couldn't find anyone matching your query: #{query}"
        @new_user = User.new
        render :new
        return
      end
    else
      @referee = User.find(params[:user][:id])
    end
    
    @tmp_referee_assignment = RefereeAssignment.new(referee: @referee, submission: @submission)
    @email = NotificationMailer.request_referee_report(@tmp_referee_assignment)
    
    render :edit_email
  end
  
  def register_new_user
    @submission = Submission.find(params[:submission_id])
    @referee = current_user.create_another_user(params[:user])
    
    if @referee.persisted?
      @tmp_referee_assignment = RefereeAssignment.new(referee: @referee, submission: @submission)
      @email = NotificationMailer.request_referee_report(@tmp_referee_assignment)
      render :edit_email
    else
      @new_user = @referee
      flash.now[:error] = "Something went wrong registering the referee. Try again?"
      render :new
    end
  end
  
  def create
    @submission = Submission.find(params[:submission_id])
    @referee = User.find(params[:referee_id])
    @referee_assignment = RefereeAssignment.new(referee: @referee,  submission: @submission, custom_email_opening: params[:custom_email_opening])
    
    if @referee_assignment.save
      redirect_to submission_path(@submission)
    else
      flash[:error] = "Something went wrong making this assignment. Try again?"
      redirect_to submission_path(@submission)
    end
  end

  def show
    @referee_assignment = RefereeAssignment.find(params[:id])
    @attachment_for_editor = @referee_assignment.attachment_for_editor if @referee_assignment.attachment_for_editor
    @attachment_for_author = @referee_assignment.attachment_for_author if @referee_assignment.attachment_for_author
    @submission = @referee_assignment.submission
  end
  
  def agree_on_behalf
    @referee_assignment = RefereeAssignment.find(params[:id])
    if @referee_assignment.agree!
      redirect_to submission_path(@referee_assignment.submission)
    else
      flash[:error] = "Couldn't record agreement."
      redirect_to submission_path(@referee_assignment.submission)
    end
  end
  
  def decline_on_behalf
    @referee_assignment = RefereeAssignment.find(params[:id])
    if @referee_assignment.decline
      redirect_to submission_path(@referee_assignment.submission)
    else
      flash[:error] = "Couldn't record agreement."
      redirect_to submission_path(@referee_assignment.submission)
    end
  end
   
  def destroy
    assignment = RefereeAssignment.find(params[:id])
    
    unless assignment.cancel!
      flash[:error] = "Failed to cancel the assignment: #{assignment.errors.full_messages.first}"
    end
    
    redirect_to submission_path(Submission.find(params[:submission_id]))
  end
  
  def download_attachment_for_editor
    assignment = RefereeAssignment.find(params[:id])
    send_file assignment.attachment_for_editor.current_path, x_sendfile: true
  end
  
  def download_attachment_for_author
    assignment = RefereeAssignment.find(params[:id])
    send_file assignment.attachment_for_author.current_path, x_sendfile: true
  end
  
  private
  
    def assigned_area_editor_or_managing_editor
      submission = Submission.find(params[:submission_id])
      unless current_user == submission.area_editor || current_user.managing_editor?
        redirect_to security_breach_path
      end
    end
    
    def author_or_assigned_referee_or_assigned_area_editor_or_managing_editor
      assignment = RefereeAssignment.find(params[:id])
      submission = assignment.submission
      
      unless current_user == submission.author || current_user == assignment.referee || current_user == submission.area_editor || current_user.managing_editor?
        redirect_to security_breach_path
      end  
    end

end
