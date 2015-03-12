FactoryGirl.define do
  
  factory :email_recipient do
    after(:build) do |email_recipient|
      email_recipient.recipient = create(:managing_editor)
      email_recipient.email = create(:email)
    end 
  end
  
end