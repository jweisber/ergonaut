FactoryGirl.define do
  
  factory :area do
    sequence(:name)       { |n| "Area #{n}" }
    sequence(:short_name) { |n| "Ar. #{n} " }
    
    factory :removed_area do
      removed             true
    end
  end
  
end