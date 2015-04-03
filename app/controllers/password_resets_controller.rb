class PasswordResetsController < ApplicationController
  
  skip_before_filter :signed_in_user
  
  def new
  end

  def create
    if user = User.find_by_email(params[:email])
      user.send_password_reset
      flash[:success] = "Email has been sent to #{params[:email]} with password reset instructions."
      redirect_to signin_path
    else
      flash.now[:error] = "I can't find a user with that email address in the system."
      render :new
    end
  end

  def edit
    @user = User.find_by_password_reset_token(params[:id])
    
    if !@user
      flash[:error] = "Invalid password-reset URL. Try creating a new one."
      render :new
    elsif 2.hours.ago > @user.password_reset_sent_at
      flash[:error] = "Your password-reset URL has expired. Please create a new one."
      render :new
    end
  end

  def update
    @user = User.find_by_password_reset_token(params[:id])
    
    unless @user
      flash.now[:error] = "Invalid password-reset URL. Try creating a new one."
      render :new
    else
      if 2.hours.ago > @user.password_reset_sent_at
        flash[:error] = "Your password-reset URL has expired. Please create a new one."
        render :new
      elsif @user.update_attributes(params[:user].permit(:password, :password_confirmation))
        @user.new_password_reset_token # reset to prevent hijacking
        @user.save
        flash[:success] = "Your password has been reset."
        sign_in @user
        redirect_to_role_home
      else
        flash.now[:error] = "Couldn't reset your password."
        render :edit
      end
    end
    
  end
end
