class OneClickEditsController < ApplicationController
  
  skip_before_filter :signed_in_user
  before_filter :authenticate
  
  def show
    redirect_to submission_path(@submission)
  end
  
  private
   
    def authenticate
      @submission = Submission.find_by_auth_token(params[:id])
      
      if @submission
        
        if @submission.area_editor
          sign_in @submission.area_editor
        else
          redirect_to signin_path unless managing_editor?
        end
        
      else
        redirect_to security_breach_path
      end
    end
end
