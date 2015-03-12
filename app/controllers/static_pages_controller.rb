class StaticPagesController < ApplicationController
  skip_before_filter :signed_in_user, except: [:guide]
  before_filter :editor, only: [:guide]

  def index
    flash.keep
    redirect_to_role_home
  end

  def guide
  end

  def about
    unless cookies[:been_here_before]
      cookies.permanent[:been_here_before] = true
      @first_time_visitor = true
    end
  end

  def peer_review
  end

  def contact
    @email = JournalSettings.journal_email
  end
  
  def security_breach
  end
  
  private
  
    def editor
      redirect_to security_breach_path unless editor?
    end
end
