class AuthorCenterController < ApplicationController
  
  before_filter :author
  before_filter :bread_crumbs
  
  def new
    @submission = Submission.new
    @areas = Area.active_ordered_by_name
  end
  
  def create
    @submission = Submission.new(params[:submission].permit(:title, :area_id, :manuscript_file))
    @submission.author = current_user
    @submission.decision = Decision::NO_DECISION
    @submission.revision_number = 0
    
    if @submission.save
      flash[:success] = "We've received your submission, the editors are being notified."
      redirect_to author_center_index_path
    else
      @areas = Area.active_ordered_by_name
      render :new
    end
  end
  
  def index
    @submissions = current_user.active_submissions
  end
  
  def archives
    @submissions = current_user.inactive_submissions
  end
  
  def withdraw
    submission = Submission.find(params[:id])
    if submission.withdraw
      flash[:success] = "Submission \##{submission.id.to_s}, \"#{submission.title}\", has been withdrawn."
    else
      flash[:error] = "Failed to withdraw Submission \##{submission.id.to_s}. Something went wrong on our end... try again?"
    end
    redirect_to author_center_index_path
  end

  private
  
    def author
      redirect_to security_breach_path unless current_user.author?
    end
end
