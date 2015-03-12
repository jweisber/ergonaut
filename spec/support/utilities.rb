include ApplicationHelper

def valid_sign_in(user)
  visit signin_path
  fill_in "Email",    with: user.email
  fill_in "Password", with: user.password
  click_button "Sign in"
  cookies[:remember_token] = user.remember_token
end

def find_withdraw_link(submission)
  find(:xpath, "//a[contains(@href, '/#{submission.id}/withdraw')]")
end

def template_files_sans_extensions
  template_files = Dir['app/views/notification_mailer/*.text.erb'].delete_if { |path| File.basename(path) =~ /^_/ }
  template_files.map! { |path| File.basename(path, '.text.erb')}
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    expect(page).to have_selector('div.alert.alert-error', text: message)
  end
end

RSpec::Matchers.define :have_success_message do |message|
  match do |page|
    expect(page).to have_selector('div.alert.alert-success', text: message)
  end
end

RSpec::Matchers.define :bounce_to do |path|
  match do |response|
    expect(response).to redirect_to(path)
  end
end

RSpec::Matchers.define :include_email do |params|
  match do |delivered_emails|
    
    switch = false
    
    delivered_emails.each do |email|
      if params[:from]
        next unless email.from.include?(params[:from])
      end

      if params[:to]
        next unless email.to.include?(params[:to])
      end
      
      if params[:cc]
        next unless email.cc.include?(params[:cc])
      end
      
      if params[:subject]
        next unless email.subject == params[:subject]
      end
      
      if params[:subject_begins]
        next unless email.subject[0,10] == params[:subject_begins][0,10]
      end
      
      if params[:body_includes]
        next unless email.body.include?(params[:body_includes])
      end
      
      switch = true
    end
    
    switch
  end
end

RSpec::Matchers.define :include_record do |params|
  match do |records|
    
    switch = false
    
    records.each do |record|
      if params[:to]
        next unless record.to.include?(params[:to])
      end
      
      if params[:cc]
        next unless record.cc.include?(params[:cc])
      end

      if params[:subject]
        next unless record.subject == params[:subject]
      end
      
      if params[:subject_begins]
        next unless record.subject[0,10] == params[:subject_begins][0,10]
      end
      
      if params[:body_includes]
        next unless record.body.include?(params[:body_includes])
      end
      
      switch = true
    end
    
    switch
  end
end

RSpec::Matchers.define :be_within_seconds_of do |t|
  match do |time|
    min = t - 10.seconds
    max = t + 10.seconds
    time > min && time < max
  end
end