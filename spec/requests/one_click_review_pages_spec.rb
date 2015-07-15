require 'spec_helper'

describe "One-click review pages" do
  
  let!(:managing_editor) { create(:managing_editor) }
  let(:submission) { create(:submission_sent_out_for_review) }
  let(:assignment) { submission.referee_assignments.first }

  context "when supplied auth_token of active referee assignment" do
    # show
    describe "show referee assignment" do
      before { visit one_click_review_path(assignment.auth_token) }
      
      it "redirects to the edit page for that assignment in the referee center" do
        expect(current_path).to eq(edit_referee_center_path(assignment))
      end
      
      it "logs us in as the assigned referee" do
        expect(page).to have_content(assignment.referee.full_name)
      end
    end
    
    # agree
    describe "agree to review" do
      before { visit agree_one_click_review_path(assignment.auth_token) }
      
      it "sets agreed to true" do
        assignment.reload
        expect(assignment.agreed).to be_true
      end
      
      it "logs us in as the assigned referee" do
        expect(page).to have_content(assignment.referee.full_name)
      end
      
      it "redirects to the edit page in the referee center and flashes success" do
        expect(current_path).to eq(edit_referee_center_path(assignment))
        expect(page).to have_success_message('Thanks')
      end
      
      it "notifies the area editor and sends a confirmation to the author" do
        expect(deliveries).to include_email(subject_begins: 'Referee Agreed', to: submission.area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Agreed', to: submission.area_editor.email)
        expect(deliveries).to include_email(subject_begins: 'Assignment Confirmation', to: assignment.referee.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Assignment Confirmation', to: assignment.referee.email)                                                  
      end
    end
    
    # decline    
    describe "decline to review" do
      before { visit decline_one_click_review_path(assignment.auth_token) }
      
      it "sets agreed to false" do
        assignment.reload
        expect(assignment.agreed).to eq(false)
      end
      
      it "logs us in as the assigned referee" do
        expect(page).to have_content(assignment.referee.full_name)
      end
      
      it "prompts for suggestions of alternate referees" do
        expect(page).to have_content('Suggestions')
      end
      
      it "notifies the editor" do
        expect(deliveries).to include_email(subject_begins: 'Referee Assignment Declined', to: submission.area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Assignment Declined', to: submission.area_editor.email)
      end
    end

    # record_decline_comment
    describe "recording a decline comment" do
      before do
        visit decline_one_click_review_path(assignment.auth_token)
        fill_in 'Suggestions:', with: 'Nulla vitae elit libero, a pharetra augue.'
        click_button 'Submit'
      end

      it "sets decline_comment" do
        assignment.reload
        expect(assignment.decline_comment).to eq('Nulla vitae elit libero, a pharetra augue.')
      end

      it "redirects to the referee center and flashes success" do
        expect(page).to have_selector('th', text: 'Invited')
        expect(page).to have_selector('th', text: 'Accepted')
        expect(page).to have_success_message('Thank you')
      end

      it "emails the area editor" do
        expect(deliveries).to include_email(subject_begins: 'Comments from', to: assignment.submission.area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Comments from', to: assignment.submission.area_editor.email)
      end
    end

    describe "recording a blank decline comment" do
      before do
        visit decline_one_click_review_path(assignment.auth_token)
        fill_in 'Suggestions:', with: '  '
        click_button 'Submit'
      end

      it "doesn't email the area editor" do
        expect(deliveries).not_to include_email(subject_begins: 'Comments from')
        expect(SentEmail.all).not_to include_record(subject_begins: 'Comments from')
      end
    end
  end
  
  context "when the assignment has already been declined" do
    # show
    describe "show referee assignment" do
      before do
        assignment.update_attributes(agreed: false)
        visit one_click_review_path(assignment.auth_token)
      end
      
      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('already declined')
      end
    end
  end
  
  context "when the assignment has been canceled" do
    # show
    describe "show referee assignment" do
      before do
        assignment.update_attributes(canceled: true)
        visit one_click_review_path(assignment.auth_token)
      end
      
      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('was canceled')
      end
    end
  end
  
  context "when the assignment has already been completed" do
    # show
    describe "show referee assignment" do
      before do
        assignment = create(:completed_referee_assignment)
        visit one_click_review_path(assignment.auth_token)
      end
      
      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('already been completed')
      end
    end    
  end
  
  context "when supplied an invalid auth_token" do
    # show
    describe "show referee assignment" do
      before { visit one_click_review_path("invalid_auth_token") }
      
      it "redirects to security breach" do
        expect(current_path).to eq(security_breach_path)
      end
    end
    
    shared_examples "a bad attempt to agree/decline using an invalid auth_token" do
      it "leaves agreed at nil" do
        assignment.reload
        expect(assignment.agreed).to be_nil
      end
      
      it "doesn't log us in" do
        expect(page).to have_content('Sign in')
      end
      
      it "redirects to security breach" do
        expect(current_path).to eq(security_breach_path)
      end
    end
    
    # agree
    describe "agree to review" do
      before { visit agree_one_click_review_path("invalid_auth_token") }
      
      it_behaves_like "a bad attempt to agree/decline using an invalid auth_token"
    end
    
    # decline    
    describe "decline to review" do
      before { visit decline_one_click_review_path("invalid_auth_token") }
      
      it_behaves_like "a bad attempt to agree/decline using an invalid auth_token"
    end

    # record_decline_comments
    describe "record decline comments" do
      before do
        @referee_assignment = { decline_comment: 'Vehicula Ridiculus Mollis'}
        put record_decline_comments_one_click_review_path('invalid_auth_token'), referee_assignment: @referee_assignment
      end

      it "leaves the decline_comment nil and bounces to security breach" do
        assignment.reload
        expect(assignment.decline_comment).to be_nil
        expect(response).to redirect_to(security_breach_path)
      end
    end
  end
end