FactoryGirl.define do
  
  factory :email do
    action                        'notify_me_new_submission'
    sender
    sequence(:subject)            { |n| "Subject #{n}" }
    sent                          false
    submission_id                 1
    referee_assignment_id         1
    options                       { create(:submission) }
    
    factory :email_with_recipients do
      after(:build) do |email|
        email.recipients << FactoryGirl.build(:recipient)
      end
    end
  end
  
end