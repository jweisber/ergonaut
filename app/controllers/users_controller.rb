class UsersController < ApplicationController
  skip_before_filter :signed_in_user, only: [:new, :create]
  before_filter :managing_editor, only: [:destroy]
  before_filter :editor, only: [:index, :fuzzy_search]
  before_filter :owner_or_editor, only: [:show]
  before_filter :owner_or_superior, only: [:edit, :update]
  before_filter :bread_crumbs

  def index
    @users = User.order(:last_name).page(params[:page])
  end

  def show
    @user = User.find(params[:id])
  end

  def fuzzy_search
    @user_hash = Hash.new
    User.find_by_fuzzy_full_name_affiliation_email(params[:query]).each do |user|
        @user_hash[user.full_name_affiliation_email] = user.id
    end
    render json: @user_hash
  end

  def new
    @user = User.new
    if current_user && current_user.editor?
      @header = "New reviewer"
      @button_text = "Assign"
    elsif current_user
      redirect_to role_home_path
    else
      @header = "Sign up"
      @button_text = "Create my account"
    end
  end

  def create

    if current_user # third party creation

      @user = current_user.create_another_user(params[:user])
      if @user.errors.none?
        flash[:success] = "User #{@user.full_name} successfully registered."
        redirect_to users_path
      else
        flash.now[:error] = "Something went wrong creating the user."
        render :new
      end

    else # new user creating own account
      @user = User.find_by_email(params[:user][:email])

      if @user
        @user.send_password_reset
        flash[:error] = "Hi #{params[:user][:first_name]} #{params[:user][:last_name]}, we're sending you an email with password-reset instructions because you're already in our system. Just follow the link in that email to set your password. Then you'll be logged in."
        redirect_to signin_path
      else
        permitted_params = params[:user].permit(:first_name, :middle_name, :last_name, :affiliation, :email, :password, :password_confirmation)
        @user = User.create(permitted_params)
        if @user.errors.none?
          sign_in @user
          flash[:success] = "Account created."
          redirect_to role_home_path
        else
          flash.now[:error] = "Something went wrong creating your account."
          render :new
        end
      end

    end

  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    params[:user].delete_if {|key, value| (key == "password" || key == "password_confirmation") && value == "12345678"}

    if @user.update_attributes(permitted_params(params[:user]))
      sign_in @user unless @user != current_user
      redirect_to @user, flash: { success: "Profile updated." }
    else
      render :edit
    end
  end

  private

    def managing_editor
      redirect_to security_breach_path unless current_user.managing_editor?
    end

    def editor
      redirect_to security_breach_path unless current_user.editor?
    end

    def owner_or_editor
      redirect_to security_breach_path unless (current_user.editor? || params[:id] == current_user.id.to_s)
    end

    def owner_or_superior
      user = User.find(params[:id])
      if user == current_user || current_user.managing_editor? || (current_user.editor? && !(user.editor?))
        true
      else
        redirect_to security_breach_path
      end
    end

    def permitted_params(params)
      if current_user.managing_editor?
        params.permit!
      elsif current_user == @user
        params.permit(:first_name, :middle_name, :last_name, :affiliation, :email, :password, :password_confirmation)
      elsif current_user.area_editor?
        params.permit(:first_name, :middle_name, :last_name, :affiliation, :email)
      else
        params.permit()
      end
    end
end
