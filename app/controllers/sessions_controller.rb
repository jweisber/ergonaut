class SessionsController < ApplicationController
  skip_before_filter :signed_in_user, only: [:new, :create]
  before_filter :consider_temporary_session, only: [:create]
  before_filter :consider_reverting_to_real_session, only: [:destroy]

  def new
  end

  def create
  	user = User.find_by_email(params[:session][:email].downcase)

  	if user && user.authenticate(params[:session][:password])
      sign_in user
      redirect_back_or(role_home_path)
    else
      @email = params[:session][:email]
      flash.now[:error] = 'Invalid login info.'
      render :new
    end
  end

  def destroy
  	sign_out
    redirect_to root_url
  end
  
  private 
  
    def consider_temporary_session
      if current_user && current_user.managing_editor? && params[:session][:user_id]
        cookies[:real_remember_token] = current_user.remember_token
        sign_in User.find(params[:session][:user_id])
        redirect_to_role_home
      end
    end
    
    def consider_reverting_to_real_session
      if cookies[:real_remember_token] && User.find_by_remember_token(cookies[:real_remember_token]) && User.find_by_remember_token(cookies[:real_remember_token]).managing_editor?
        sign_out
        sign_in User.find_by_remember_token(cookies[:real_remember_token])
        cookies[:real_remember_token] = nil
        redirect_to_role_home
      end
    end
end
