require 'spec_helper'

describe "Referee assignment pages" do

  let!(:managing_editor) { create(:managing_editor) }
  let(:wrong_area_editor) { create(:area_editor) }
  let(:submission) { create(:submission_with_one_completed_referee_assignment_one_open_request) }
  let(:assigned_area_editor) { submission.area_editor }
  let(:existing_user) { create(:user) }
  
  shared_examples "all actions are accessible" do
    # new
    describe "new referee assignment" do
      before { visit new_submission_referee_assignment_path(submission) }
      
      it "provides a search form for" do
        expect(page).to have_field('Search')
      end
      
      it "provides a registration form" do
        expect(page).to have_content('New user')
        expect(page).to have_field('First name')
        expect(page).to have_field('Middle name')
        expect(page).to have_field('Last name')
        expect(page).to have_field('Affiliation')
        expect(page).to have_field('Email')
      end
    end
    
    # existing user
    describe "assigning an existing user as referee" do
      before do
        existing_user
        visit new_submission_referee_assignment_path(submission)
      end
      
      context "when searching for an editor", js: true do
        before { fill_in 'Search', with: managing_editor.full_name }
        it "doesn't show them in the search results" do
          expect(page).not_to have_link(managing_editor.full_name_affiliation_email)
        end
      end
      
      context "when searching for a non-editor", js: true do
        before { fill_in 'Search', with: existing_user.full_name }
        it "does show them in the search results" do
          expect(page).to have_link(existing_user.full_name_affiliation_email)
        end
      end
      
      context "selecting the existing user with typeahead", js: true do
        before do
          fill_in 'Search', with: existing_user.full_name
          click_link existing_user.full_name_affiliation_email
          page.find_button('existing_user_submit_button').trigger(:click)
        end
        
        it "presents a request email for editing" do
          opening_field = find_field('custom_email_opening')
          expect(opening_field.value).to match("Dear #{existing_user.full_name}")
        end
      end
      
      context "using old fashioned http" do
        before do
          existing_user.update_attributes(first_name: 'Unique', last_name: 'Snowflake')
          fill_in 'Search', with: existing_user.full_name
          click_button 'existing_user_submit_button'
        end
        
        it "presents a request email for editing" do
          opening_field = find_field('custom_email_opening')
          expect(opening_field.value).to match("Dear #{existing_user.full_name}")
        end
      end
    end
    
    # register new user
    describe "register a new user as a referee" do
      before do
        visit new_submission_referee_assignment_path(submission)
        fill_in 'First name', with: 'Major'
        fill_in 'Middle name', with: 'Major'
        fill_in 'Last name', with: 'Major'
        fill_in 'Affiliation', with: 'University of Majoristan'
        fill_in 'Email', with: 'major.m.major@majoristan.edu'
        click_button('new_user_submit_button')
      end
      
      it "registers the user" do
        new_user = User.find_by_email('major.m.major@majoristan.edu')
        expect(new_user).not_to be_nil
      end
      
      it "emails the user a notification" do
        new_user = User.find_by_email('major.m.major@majoristan.edu')
        expect(deliveries).to include_email(subject_begins: 'You\'ve been registered with Ergo', to: new_user.email)
        expect(SentEmail.all).to include_record(subject_begins: 'You\'ve been registered with Ergo', to: new_user.email)
      end
      
      it "presents a request email for editing" do
        opening_field = find_field('custom_email_opening')
        expect(opening_field.value).to match("Dear Major Major Major")
      end
    end
    
    # edit page for request email
    describe "edit review-request email page" do
      before do
        visit new_submission_referee_assignment_path(submission)
        fill_in 'First name', with: 'Major'
        fill_in 'Middle name', with: 'Major'
        fill_in 'Last name', with: 'Major'
        fill_in 'Affiliation', with: 'University of Majoristan'
        fill_in 'Email', with: 'major.m.major@majoristan.edu'
        click_button('new_user_submit_button')
      end
      
      it "has a field for editing the opening of the email" do
        opening_field = find_field('custom_email_opening')
        expect(opening_field.value).to match("Dear Major Major Major")
      end
      
      it "displays the email body (static)" do
        expect(page).to have_content('View submission: http://')
      end
      
      it "has buttons to Cancel/Send" do
        expect(page).to have_link('Cancel', href: new_submission_referee_assignment_path(submission))
        expect(page).to have_button('Send')
      end
    end
    
    # create
    describe "create a new referee assignment" do
      before do
        managing_editor
        visit new_submission_referee_assignment_path(submission)
        fill_in 'First name', with: 'Major'
        fill_in 'Middle name', with: 'Major'
        fill_in 'Last name', with: 'Major'
        fill_in 'Affiliation', with: 'University of Majoristan'
        fill_in 'Email', with: 'major.m.major@majoristan.edu'
        click_button('new_user_submit_button')
        fill_in 'custom_email_opening', with: 'Custom opening text'
        click_button('Send')
        @new_user = User.find_by_email('major.m.major@majoristan.edu')
      end
      
      it "assigns the referee" do
        expect(submission.referees).to include(@new_user)
      end
      
      it "sends the request email with the custom opening (cc editors)" do
        expect(last_email.subject).to match('Referee Request')
        expect(last_email.to).to include(@new_user.email)
        expect(last_email.cc).to include(managing_editor.email)
        expect(last_email.cc).to include(assigned_area_editor.email)
        expect(last_email.text_part.body).to match('Custom opening text')
        expect(last_email.attachments.size).to eq(1)
        expect(last_email.attachments[0].content_type).to start_with('application/pdf')
        
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Request', to: @new_user.email, cc: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Request', to: @new_user.email, cc: assigned_area_editor.email)
      end
      
      it "redirects to the submission's show page" do
        expect(current_path).to eq(submission_path(submission))
      end
    end
    
    # show
    describe "show the referee's report" do
      before do
        @referee_assignment = submission.referee_assignments.first
        visit submission_referee_assignment_path(submission, @referee_assignment)
      end
      
      it "displays the report" do
        expect(page).to have_content(@referee_assignment.comments_for_editor)
        expect(page).to have_link('', href: @referee_assignment.attachment_for_editor.url)
        expect(page).to have_content(@referee_assignment.comments_for_author)
        expect(page).to have_link('', href: @referee_assignment.attachment_for_author.url)
        expect(page).to have_content(@referee_assignment.recommendation)
      end
      
      it "has working link to attachment for editor" do
        find(:xpath, "//a[@href='#{@referee_assignment.attachment_for_editor.url}']").click
        expect(page.response_headers['Content-Type']).to eq('application/pdf')
      end
      
      it "has working link to attachment for author" do
        find(:xpath, "//a[@href='#{@referee_assignment.attachment_for_author.url}']").click
        expect(page.response_headers['Content-Type']).to eq('application/pdf')
      end
    end
    
    # agree_on_behalf
    describe "agreeing on the reviewer's behalf" do
      before do
        @assignment = submission.referee_assignments.last
        visit agree_on_behalf_submission_referee_assignment_path(submission, @assignment)
      end
      
      it "sets agreed to true" do
        @assignment.reload
        expect(@assignment.agreed).to be_true
      end
      
      it "displays the submission's page" do
        expect(current_path).to eq(submission_path(submission))
      end
      
      it "notifies the area editor (cc managing editors) and sends a confirmation to the author (cc area editor)" do
        expect(deliveries).to include_email(subject_begins: 'Referee Agreed', to: assigned_area_editor.email, cc: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Agreed', to: assigned_area_editor.email, cc: managing_editor.email)
        
        expect(deliveries).to include_email(subject_begins: 'Assignment Confirmation', to: @assignment.referee.email, cc: assigned_area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Assignment Confirmation', to: @assignment.referee.email, cc: assigned_area_editor.email)
      end
    end
    
    # decline_on_behalf
    describe "declining on the reviewer's behalf" do
      before do
        @assignment = submission.referee_assignments.last
        visit decline_on_behalf_submission_referee_assignment_path(submission, @assignment)
      end
      
      it "sets agreed to false" do
        @assignment.reload
        expect(@assignment.agreed).to eq(false)
      end
      
      it "display's the submission's page" do
        expect(current_path).to eq(submission_path(submission))
      end
      
      it "notifies the editor" do
        expect(deliveries).to include_email(subject_begins: 'Referee Assignment Declined', to: assigned_area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Assignment Declined', to: assigned_area_editor.email)
      end
    end
    
    # destroy
    describe "'destroying' (canceling, really) an assignment" do
      before do
        @assignment = submission.referee_assignments.first
        delete submission_referee_assignment_path(submission, @assignment)
      end
      
      it "sets canceled to true" do
        @assignment.reload
        expect(@assignment.canceled).to be_true
      end
      
      it "emails a notification to the referee" do
        expect(deliveries).to include_email(subject_begins: 'Cancelled Referee Request', to: @assignment.referee.email, cc: assigned_area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Cancelled Referee Request', to: @assignment.referee.email, cc: assigned_area_editor.email)
      end
    end
  end
  
  context "when logged in as a managing editor" do
    before { valid_sign_in(managing_editor) }
    
    it_behaves_like "all actions are accessible"
  end
  
  context "when logged in as the assigned area editor" do
    before { valid_sign_in(assigned_area_editor) }
    
    it_behaves_like "all actions are accessible"
  end
  
  shared_examples "no actions are accessible" do |redirect_path|
       
    # new
    describe "new referee assignment" do
      before { visit new_submission_referee_assignment_path(submission) }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # select_existing_user
    describe "select an existing user as a referee" do
      before do
        post select_existing_user_submission_referee_assignments_path(submission), user: { id: existing_user.id }
      end
      
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
    
    # register_new_user
    describe "register a new user as a referee" do
      before do
        new_user = build(:user)
        post register_new_user_submission_referee_assignments_path(submission), user: new_user
      end
      
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
    
    # create
    describe "create a new referee assignment" do
      before do
        post submission_referee_assignments_path(submission), referee_id: existing_user.id
      end
      
      it "doesn't assign the referee" do
        expect(submission.referees).not_to include(existing_user)
      end
      
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end

    # show
    describe "shows the referee's report" do
      before do
        @referee_assignment = submission.referee_assignments.first
        visit submission_referee_assignment_path(submission, @referee_assignment)
      end

      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # agree_on_behalf
    describe "agreeing on the reviewer's behalf" do
      before do
        @assignment = submission.referee_assignments.last
        visit agree_on_behalf_submission_referee_assignment_path(submission, @assignment)
      end

      it "leaves agreed nil" do
        @assignment.reload
        expect(@assignment.agreed).to be_nil
      end

      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # decline_on_behalf
    describe "declining on the reviewer's behalf" do
      before do
        @assignment = submission.referee_assignments.last
        visit decline_on_behalf_submission_referee_assignment_path(submission, @assignment)
      end

      it "leaves agreed nil" do
        @assignment.reload
        expect(@assignment.agreed).to be_nil
      end

      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end

    # destroy
    describe "'destroying' (canceling, really) an assignment" do
      before do
        @assignment = submission.referee_assignments.first
        delete submission_referee_assignment_path(submission, @assignment)
      end

      it "leaves canceled false and doesn't email the referee" do
        expect(@assignment.canceled).to eq(false)
        expect(deliveries).not_to include_email(subject_begins: 'Cancelled Referee Request')
      end
    end
    
    # download_attachment_for_editor
    describe "downloading the attachment for the editor" do
      before do
        @assignment = submission.referee_assignments.first
        get @assignment.attachment_for_editor.url
      end

      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
    
    # download_attachment_for_author
    describe "downloading the attachment for the editor" do
      before do
        @assignment = submission.referee_assignments.first
        get @assignment.attachment_for_author.url
      end

      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
  end
  
  context "when logged in as the wrong area editor" do
    before { valid_sign_in(wrong_area_editor) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when logged in as an author/referee" do
    before { valid_sign_in(create(:user)) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when not logged in" do
    it_behaves_like "no actions are accessible", :signin_path
  end
end