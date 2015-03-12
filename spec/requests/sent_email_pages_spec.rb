require 'spec_helper'

describe "SentEmail pages" do
  
  let(:user) { create(:user) }
  let(:area_editor) { create(:area_editor) }
  let(:managing_editor) { create(:managing_editor) }
  
  let(:new_submission) { create(:submission) }
  let(:submission_with_one_completed_referee_assignment) { create(:submission_with_one_completed_referee_assignment) }
  let(:major_revisions_requested_submission) { create(:major_revisions_requested_submission) }
  
  subject { page }

  shared_examples_for "all actions are accessible" do
    # index
    describe "index page" do
      before { visit submission_sent_emails_path(@submission) }
      
      it "lists all emails connected with the submission" do
        emails = SentEmail.where(submission_id: @submission.id)
        emails.each do |email|
          expect(page).to have_content(email.to)
          expect(page).to have_link(email.subject)
          expect(page).to have_content(email.date_sent_pretty)
        end
      end
    end
    
    # show
    describe "show page" do
      before do
        @email = SentEmail.where(submission_id: @submission.id).sample
        visit submission_sent_email_path(@submission, @email)
      end
      
      it "shows the email" do
        expect(page).to have_content(@email.to)
        expect(page).to have_content(@email.cc)
        expect(page).to have_content(@email.subject)
        expect(page).to have_content(@email.datetime_sent_pretty)
        expect(page).to have_content(@email.body)
        expect(page).to have_content(@email.attachments)
      end
      
      context "for an unassociated email" do
        before do
          User.first.send_password_reset
          visit submission_sent_email_path(@submission, SentEmail.last)
        end
        
        it "redirects to security_breach" do
          expect(current_path).to eq(security_breach_path)
        end
      end
    end
  end

  context "when logged in as managing editor" do
    before do
      @submission = major_revisions_requested_submission
      valid_sign_in(managing_editor)
    end
    
    it_behaves_like "all actions are accessible"
  end
  
  context "when logged in as the assigned area editor" do
    before do
      @submission = major_revisions_requested_submission
      valid_sign_in(@submission.area_editor)
    end
    
    it_behaves_like "all actions are accessible"
  end
  
  shared_examples_for "no actions are accessible" do |redirect_path|
    # index
    describe "index page" do
      before { visit submission_sent_emails_path(new_submission) }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # show
    describe "show page" do
      before do
        submission_with_one_completed_referee_assignment
        visit submission_sent_email_path(SentEmail.first.submission, SentEmail.first)
      end
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
  end
  
  context "when logged in as an unassigned area editor" do
    before { valid_sign_in(area_editor) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when logged in as author/referee" do
    before { valid_sign_in(user) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when not logged in" do
    it_behaves_like "no actions are accessible", :signin_path
  end
  
end
