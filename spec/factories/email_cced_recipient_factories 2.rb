FactoryGirl.define do
  
  factory :email_cced_recipient do
    after(:build) do |email_cced_recipient|
      email_cced_recipient.cced_recipient = create(:managing_editor)
      email_cced_recipient.email = create(:email)
    end 
  end
  
end