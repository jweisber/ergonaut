module SessionsHelper

  def sign_in(user)
    cookies[:remember_token] = user.remember_token
    self.current_user = user
  end

  def signed_in?
    !current_user.nil?
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= User.find_by_remember_token(cookies[:remember_token])
  end
  
  def editor?
    current_user && current_user.editor?
  end
  
  def managing_editor?
    current_user && current_user.managing_editor?
  end
  
  def area_editor?
    current_user && current_user.area_editor?
  end

  def sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end
  
  def store_location
    session[:return_to] = request.url
  end
  
  def redirect_to_role_home
    redirect_to role_home_path
  end
  
  def role_home_path
    if current_user  # logged in?
      if current_user.editor?  # editor?
        submissions_path
      else  # author/referee?
        if current_user.has_pending_referee_assignments?  # pending referee assignments
          referee_center_index_path
        else  # author
          author_center_index_path
        end
      end
    else
      signin_path
    end
  end
  
  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end
end