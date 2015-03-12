# From Railscasts: http://railscasts.com/episodes/275-how-i-test
module MailerMacros
  def deliveries
    ActionMailer::Base.deliveries
  end
  
  def last_email
    ActionMailer::Base.deliveries.last
  end
  
  def penultimate_email
    ActionMailer::Base.deliveries[-2]
  end
  
  def emails_ago(n)
    ActionMailer::Base.deliveries[-n+1]
  end
  
  def reset_email
    ActionMailer::Base.deliveries.clear
  end
  
  def find_email(params)
    ActionMailer::Base.deliveries.each do |email|
      if params[:from]
        next unless email.from.include?(params[:from])
      end

      if params[:to]
        next unless email.to.include?(params[:to])
      end
    
      if params[:cc]
        if params[:cc].kind_of?(Array)
          next unless (params[:cc] - email.cc).empty?
        else
          next unless email.cc.include?(params[:cc])
        end
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

      return email
    end
    
    return nil
  end
end