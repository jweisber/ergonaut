FactoryGirl.define do
  
  factory :area_editor_assignment do
    after(:build) do |area_editor_assignment|
      area_editor_assignment.area_editor = create(:area_editor)
      area_editor_assignment.submission = create(:submission)
    end    
  end
  
end