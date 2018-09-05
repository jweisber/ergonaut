require 'spec_helper'

describe "One-click review pages" do

  let!(:managing_editor) { create(:managing_editor) }
  let(:submission) { create(:submission_sent_out_for_review) }
  let(:assignment) { submission.referee_assignments.first }
  before { assignment.update_attributes(created_at: 121.seconds.ago) }

  context "when a response comes in right away" do
    before {assignment.update_attributes(created_at: 100.seconds.ago)}

    describe "agree to review" do
      before { visit agree_one_click_review_path(assignment.auth_token) }

      it "asks for confirmation" do
        expect(page).to have_content("Please confirm that you agree")
      end

      it "doesn't yet record the agreement" do
        assignment.reload
        expect(assignment.agreed).to be_nil
      end

      context "when the agreement is confirmed" do
        before { click_button "Yes, I Agree" }
        it "records the agreement and redirects to the edit report page" do
          assignment.reload
          expect(assignment.agreed).to be_true
          expect(current_path).to eq(edit_report_referee_center_path(assignment))
        end
      end

      context "when the user cancels" do
        before { click_link "Cancel" }
        it "redirects to the edit response page" do
          assignment.reload
          expect(assignment.agreed).to be_nil
          expect(current_path).to eq(edit_response_referee_center_path(assignment))
        end
      end
      
    end
  end

  context "when supplied auth_token of active referee assignment" do
    # show
    describe "show referee assignment" do
      before { visit one_click_review_path(assignment.auth_token) }

      it "redirects to the edit response page for that assignment" do
        expect(current_path).to eq(edit_response_referee_center_path(assignment))
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

      it "redirects to the edit report page and flashes success" do
        expect(current_path).to eq(edit_report_referee_center_path(assignment))
        expect(page).to have_success_message('Thanks')
      end

      it "emails a confirmation to the author (cc area editor)" do
        expect(deliveries).to include_email(subject_begins: 'Assignment Confirmation',
                                            to: assignment.referee.email,
                                            cc: assignment.submission.area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Assignment Confirmation',
                                                to: assignment.referee.email,
                                                cc: assignment.submission.area_editor.email)
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

      it "prompts for alternate referee suggestions" do
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
        expect(current_path).to eq referee_center_index_path
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
        expect(page).to have_error_message('That request has already been declined.')
      end
    end

    # agree
    describe "agree to assignment" do
      before do
        assignment.update_attributes(agreed: false)
        visit agree_one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('That request has already been declined.')
      end
    end

    # decline
    describe "decline the assignment" do
      before do
        assignment.update_attributes(agreed: false)
        visit decline_one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('That request has already been declined.')
      end
    end
  end

  context "when the assignment has already been agreed to" do
    # show
    describe "show referee assignment" do
      before do
        assignment.update_attributes(agreed: true)
        visit one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the edit report page" do
        expect(current_path).to eq(edit_report_referee_center_path(assignment))
        expect(page).to have_error_message('This request has already been accepted.')
      end
    end

    # agree
    describe "agree to assignment" do
      before do
        assignment.update_attributes(agreed: true)
        visit agree_one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the edit report page" do
        expect(current_path).to eq(edit_report_referee_center_path(assignment))
        expect(page).to have_error_message('This request has already been accepted.')
      end
    end

    # decline
    describe "decline the assignment" do
      before do
        assignment.update_attributes(agreed: true)
        visit decline_one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the edit report page" do
        expect(current_path).to eq(edit_report_referee_center_path(assignment))
        expect(page).to have_error_message('This request has already been accepted.')
      end
    end

    # record_decline_comments
    describe "record decline comments" do
      before do
        assignment.update_attributes(agreed: true)
        put record_decline_comments_one_click_review_path(assignment.auth_token),
            referee_assignment: { decline_comment: 'Ask someone else' }
      end

      it "doesn't record the comment" do
        expect(assignment.reload.decline_comment).to be_nil
      end

      it "flashes an error and redirects to the edit report page" do
        expect(response).to bounce_to(edit_report_referee_center_path(assignment))
        follow_redirect!
        expect(response.body).to match /This request has already been accepted/
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
        expect(page).to have_error_message('That request was canceled.')
      end
    end

    # agree
    describe "show referee assignment" do
      before do
        assignment.update_attributes(canceled: true)
        visit agree_one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('That request was canceled.')
      end
    end

    # decline
    describe "show referee assignment" do
      before do
        assignment.update_attributes(canceled: true)
        visit decline_one_click_review_path(assignment.auth_token)
      end

      it "flashes an error and redirects to the referee center" do
        expect(current_path).to eq(referee_center_index_path)
        expect(page).to have_error_message('That request was canceled.')
      end
    end

    #decline_comment
    describe "show referee assignment" do
      before do
        assignment.update_attributes(canceled: true)
        put record_decline_comments_one_click_review_path(assignment.auth_token),
            referee_assignment: { decline_comment: 'Try someone else.' }
      end

      it "doesn't record the comment" do
        expect(assignment.reload.decline_comment).to be_nil
      end

      it "flashes an error and redirects to the referee center" do
        expect(response).to bounce_to(referee_center_index_path)
        follow_redirect!
        expect(response.body).to match /That request was canceled/
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
