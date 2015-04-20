FactoryGirl.define do
  
  factory :submission do
    sequence(:title)  { |n| "Title #{n}" }
    author
    manuscript_file   { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf')) }
    area
    
    factory :submission_sent_for_review_without_area_editor do
      before(:create) do |submission|
        submission.referee_assignments << create(:referee_assignment, submission: submission, referee: create(:user))
      end
    end
    
    factory :submission_assigned_to_area_editor do
      area_editor
      
      factory :submission_assigned_to_area_editor_overdue_for_internal_review do
        created_at    JournalSettings.days_for_initial_review.days.ago
      end
      
      factory :submission_sent_out_for_review do
        before(:create) do |submission|
          submission.referee_assignments << create(:referee_assignment, submission: submission, referee: create(:user))
        end
      end
      
      factory :submission_with_two_agreed_referee_assignments do
        before(:create) do |submission|
          submission.referee_assignments << create(:canceled_referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:declined_referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:agreed_referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
        end
      end
      
      factory :submission_with_one_completed_referee_assignment do
        before(:create) do |submission|
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
        end
        
        factory :submission_with_one_completed_referee_assignment_one_open_request do
          before(:create) do |submission|
            submission.referee_assignments << create(:referee_assignment, submission: submission, referee: create(:user))
          end
          
          factory :submission_withdrawn do
            withdrawn           true
            archived            true
          end
        end
      end
      
      factory :submission_with_one_pending_referee_assignment_one_completed do
        before(:create) do |submission|
          submission.referee_assignments << create(:referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
        end
      end

      factory :submission_with_two_completed_referee_assignments do
        before(:create) do |submission|
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
        end
        
        factory :submission_with_reject_decision_not_yet_approved do
          after(:create) { |submission| submission.update_attributes(decision: Decision::REJECT) }
        end
      
        factory :submission_with_major_revisions_decision_not_yet_approved do
          after(:create) { |submission| submission.update_attributes(decision: Decision::MAJOR_REVISIONS) }
        end
      
        factory :submission_with_minor_revisions_decision_not_yet_approved do
          after(:create) { |submission| submission.update_attributes(decision: Decision::MINOR_REVISIONS) }
        end
      
        factory :submission_with_accept_decision_not_yet_approved do
          after(:create) { |submission| submission.update_attributes(decision: Decision::ACCEPT) }
        end
      end
      
      factory :desk_rejected_submission do
        decision                    Decision::REJECT
        area_editor_comments_for_managing_editors 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
        area_editor_comments_for_author           'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
        decision_approved           true
        decision_entered_at         Time.current - 1.week
        archived                    true
      
        factory :rejected_after_review_submission do
          before(:create) do |submission|
            submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
            submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
          end
        
          factory :major_revisions_requested_submission do
            decision            Decision::MAJOR_REVISIONS
            decision_approved   true
          end
      
          factory :minor_revisions_requested_submission do
            decision            Decision::MINOR_REVISIONS
            decision_approved   true
          end
      
          factory :accepted_submission do
            decision            Decision::ACCEPT
            decision_approved   true
          end
        end
        
      end
      
    end
    
    factory :first_revision_submission do
      before(:create) do |submission|
        submission.revision_number = 1
        submission.original = create(:major_revisions_requested_submission)
      end
      
      factory :first_revision_submission_minor_revisions_requested do
        before(:create) do |submission|
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
          submission.decision = Decision::MINOR_REVISIONS
          submission.decision_approved = true
        end
      end
    end
    
    factory :second_revision_submission do
      before(:create) do |submission|
        submission.revision_number = 2        
        submission.original = create(:first_revision_submission_minor_revisions_requested).original
      end
      
      factory :second_revision_submission_minor_revisions_requested do
        before(:create) do |submission|
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
          submission.referee_assignments << create(:completed_referee_assignment, submission: submission, referee: create(:user))
          submission.decision = Decision::MINOR_REVISIONS
          submission.decision_approved = true
        end          
      end
      
    end
  end
  
end