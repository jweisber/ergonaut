require 'spec_helper'

describe SentEmail do
  
  let(:email) { create(:sent_email) }
  subject { email }
  
  it { should respond_to(:submission) }
  it { should respond_to(:referee_assignment) }
  it { should respond_to(:action) }
  it { should respond_to(:subject) }
  it { should respond_to(:to) }
  it { should respond_to(:cc) }
  it { should respond_to(:body) }
  it { should respond_to(:attachments) }
  it { should be_valid }

  
  # validations
   
  it "is not valid without an action" do
    email.action = ''
    email.should_not be_valid
  end
  
  it "is not valid without a subject" do
    email.subject = ''
    email.should_not be_valid
  end
  
  it "is not valid without to" do
    email.to = ''
    email.should_not be_valid
  end
  
  it "is not valid without a body" do
    email.body = ''
    email.should_not be_valid
  end
  
  
  # class methods
  
  describe ".create_from_message" do
    before do
      @user = FactoryGirl.create(:user)
      @user.new_password_reset_token
      @message = NotificationMailer.notify_password_reset(@user)
      SentEmail.create_from_message(@message)
    end
    
    it "creates a record in the database with the message's action, subject, to, cc, body, and attachments" do
      record = SentEmail.last
      expect(record).not_to be_nil
      expect(record.action).to eq('notify_password_reset')
      expect(record.subject).to eq('Password Reset')
      expect(record.to).to eq(@user.email)
      expect(record.cc).to be_blank
      expect(record.body).to match('To reset your password')
      expect(record.attachments).to be_blank
    end
  end
    
  
  # instance methods
  describe "#date_sent_pretty" do
    it "returns created_at in Mon. D, YYYY format" do
      email.created_at = Date.new(2013, 12, 9)
      expect(email.date_sent_pretty).to eq("Dec. 9, 2013")
    end
  end
  
  describe "#datetime_sent_pretty" do
    it "returns created_at in Mon. D, YYYY @ H:MM PM format" do
      email.created_at = DateTime.new(2013, 12, 9, 13, 30)
      expect(email.datetime_sent_pretty).to eq("Dec. 9, 2013 @  1:30 PM")
    end
  end
  
end
