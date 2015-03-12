FactoryGirl.define do
  
  factory :user, aliases: [:author, :referee, :sender, :recipient] do
    sequence(:first_name) { |n| "Jane#{n}" }
    sequence(:last_name)  { |n| "Doe#{n}"}
    sequence(:email)      { |n| "jane#{n}@example.com" }
    password              "secret"
    password_confirmation "secret"
    
    factory :managing_editor do
      managing_editor     true
      area_editor         false
      author              false
      referee             false
    end
    
    factory :area_editor do
      managing_editor     false
      area_editor         true
      author              false
      referee             false
    end
  end
  
end