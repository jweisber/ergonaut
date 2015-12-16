class SubmissionsController < ApplicationController
  
  before_filter :assigned_area_editor_or_managing_editor, except: [:index, :download]
  before_filter :editor, only: [:index]  
  before_filter :managing_editor_or_assigned_author_referee_or_area_editor, only: [:download]
  before_filter :managing_editor, only: [:edit_manuscript_file, :update_manuscript_file]
  before_filter :bread_crumbs

	def index
    if current_user.managing_editor?
      @submissions = Submission.where(archived: false).includes(:author, :area, :area_editor, :referee_assignments, :referees) 
    else
      @submissions = current_user.ae_submissions.where(archived: false).includes(:author, :area, :area_editor, :referee_assignments, :referees)
    end
  end

  def show
    @submission = Submission.find(params[:id])
    redirect_to archive_path(@submission) if @submission.archived?
    @referee_assignments = active_referee_assignments(@submission)
  end

  def edit
    @current_user = current_user
    @submission = Submission.find(params[:id])
    @submission.area_editor ||= @submission.build_area_editor_assignment.build_area_editor

    @all_area_editors = User.area_editors_ordered_by_last_name
  end

  def update
    @current_user = current_user
    @submission = Submission.find(params[:id])

    if @submission.update_attributes(permitted_params)
      if @submission.archived?
        redirect_to archive_path(@submission), flash: { success: "Submission archived." }
      else
        redirect_to submission_path(@submission)
      end
    else
      @submission.area_editor ||= @submission.build_area_editor_assignment.build_area_editor
      @all_area_editors = User.area_editors_ordered_by_last_name
      flash.now[:error] = "Something went wrong saving your changes."
      render :edit
    end
  end
  
  def download
    send_file @submission.reload.manuscript_file.current_path, x_sendfile: true
  end
  
  def edit_manuscript_file
  end
  
  def update_manuscript_file
    if params[:submission] && params[:submission][:manuscript_file]
      path = @submission.manuscript_file.current_path
      FileUtils.copy(path, path + '.bak') if File.exist?(path)
      if @submission.update_attributes(manuscript_file: params[:submission][:manuscript_file])
        flash.now[:success] = "Manuscript file replaced."
        @referee_assignments = active_referee_assignments(@submission)
        render :show
      else
        flash.now[:error] = "Something went wrong replacing the file."
        render :edit_manuscript_file
      end
    else
      flash.now[:error] = "Did you forget to choose a new file?"
      render :edit_manuscript_file
    end
  end

  private
  
    def managing_editor_or_assigned_author_referee_or_area_editor
      @submission = Submission.find(params[:id])
      if current_user.managing_editor?
        return 
      elsif current_user == @submission.author
        return
      elsif current_user == @submission.area_editor
        return
      elsif (@submission.referees.include?(current_user) || 
             @submission.latest_version.referees.include?(current_user))
        return
      else
        redirect_to security_breach_path
      end
    end

    def assigned_area_editor_or_managing_editor
      @submission = Submission.find(params[:id]) if params[:id]
      
      unless current_user.managing_editor? or (@submission and current_user == @submission.area_editor)
        redirect_to security_breach_path
      end
    end
    
    def managing_editor
      redirect_to security_breach_path unless current_user.managing_editor?
    end
    
    def editor
      redirect_to security_breach_path unless current_user.editor?
    end
    
    def permitted_params
      if current_user.managing_editor?
        # reformat first, because accepts_nested_attributes_for sucks with has_one :through
        params[:submission][:area_editor] = params[:submission][:user][:id].empty? ? nil : User.find(params[:submission][:user][:id])
        params[:submission].delete(:user)
        params[:submission].delete_if do |key, value|  # ignore blank comments
          (key == 'area_editor_comments_for_managing_editors' || key == 'area_editor_comments_for_author') && (value.nil? || value.empty?)
        end
        params[:submission].permit!
      elsif current_user.area_editor?
        params[:submission].permit(:area_editor_comments_for_managing_editors, :area_editor_comments_for_author, :decision)
      else
        params[:submission].permit()
      end
    end

    def active_referee_assignments(submission)
      submission.referee_assignments.where("canceled = ? OR canceled IS NULL", false).includes(:referee)
    end
end
