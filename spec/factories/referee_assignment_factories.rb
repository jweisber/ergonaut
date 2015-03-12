FactoryGirl.define do
  
  factory :referee_assignment do
    referee    
    submission
    agreed  nil
    
    factory :canceled_referee_assignment do
      canceled             true
    end
    
    factory :declined_referee_assignment do
      agreed               false
      decline_comment      'Ask someone else.'
      declined_at          Time.current
    end
    
    factory :agreed_referee_assignment do
      agreed                true
      agreed_at           Time.current
      
      factory :agreed_referee_assignment_for_revised_submission do
        submission          { create(:first_revision_submission) }
      end
      
      factory :completed_referee_assignment do
        comments_for_editor   'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
        attachment_for_editor { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf')) }
        comments_for_author   'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum'
        attachment_for_author { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf')) }
        recommendation        Decision::MAJOR_REVISIONS
        report_completed      true
        report_completed_at   Time.current
      end
    end
    
  end
  
end