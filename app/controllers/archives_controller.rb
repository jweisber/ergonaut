class ArchivesController < ApplicationController
  
  before_filter :editor
  before_filter :assigned_area_editor_or_managing_editor
  before_filter :managing_editor, only: [:update]
  before_filter :bread_crumbs
  
  def index
    if current_user.managing_editor?
      @submissions = Submission.where(archived: true).includes(:area).page(params[:page])
    else
      @submissions = current_user.ae_submissions.where(archived: true).includes(:area).page(params[:page])
    end
  end

  def show
    @submission = Submission.find(params[:id])
    @referee_assignments = @submission.referee_assignments.where("canceled = ? OR canceled IS NULL", false).includes(:referee)
  end

  def update
    redirect_to security_breach_path unless current_user.managing_editor?
    
    @submission = Submission.find(params[:id])
    if @submission.unarchive(current_user)
      redirect_to submissions_path
    else
      flash.now[:error] = "Something went wrong unarchiving \##{@submission.id.to_s}."
      render :show
    end
  end
  
  
  private
  
    def editor
      unless current_user.editor?
        redirect_to security_breach_path
      end
    end

    def managing_editor
      unless current_user.managing_editor?
        redirect_to security_breach_path
      end
    end

    def assigned_area_editor_or_managing_editor
      if !current_user.managing_editor?
        if params[:id] && current_user != Submission.find(params[:id]).area_editor
          redirect_to security_breach_path
        end
      end
    end
end
