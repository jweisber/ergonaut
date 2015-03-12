require 'spec_helper'

describe "Archives pages" do
  
  let(:user) { create(:user) }
  let(:area_editor) { create(:area_editor) }
  let(:managing_editor) { create(:managing_editor) }
  
  let!(:desk_rejected_submission) { create(:desk_rejected_submission) }
  let!(:accepted_submission) { create(:accepted_submission) }
  
  subject { page }
  
  context "when logged in as managing editor" do
    before { valid_sign_in(managing_editor) }
    
    #index 
    
    describe "index page" do
      before { visit archives_path }
      
      it { should have_selector('ul.breadcrumb', text: 'Archives') }
      it { should have_link(desk_rejected_submission.title) }
      it { should have_link(accepted_submission.title) }
    end
    
    #show
    
    describe "show archived submission page" do
      before { visit archive_path(accepted_submission) }
      
      it { should have_selector('ul.breadcrumb', text: 'Archives') }
      it { should have_selector('ul.breadcrumb', text: "Submission \##{accepted_submission.id}") }
      it { should have_selector('h3', text: accepted_submission.title) }
      
      it { should have_button('Unarchive') }
      
      it { should have_content(accepted_submission.area_editor_comments_for_managing_editors) }
      it { should have_content(accepted_submission.area_editor_comments_for_author) }
      
      it "lists all non-canceled referee assignments" do
        accepted_submission.non_canceled_referee_assignments.each do |ra|
          expect(page).to have_content(ra.referee.full_name)
        end
      end
      
      it "links to completed referee reports" do
        report_path = archive_referee_assignment_path(accepted_submission, accepted_submission.referee_assignments.first)
        expect(page).to have_link('', href: report_path)
      end
    end
    
    describe "show archived submission's referee report page" do
      before do
        visit archive_path(accepted_submission)
        @referee_assignment = accepted_submission.referee_assignments.first
        report_path = archive_referee_assignment_path(accepted_submission, @referee_assignment)
        report_link = find(:xpath, "//a[@href='" + report_path + "']")
        report_link.click        
      end
      
      it { should have_selector('ul.breadcrumb', text: 'Archives') }
      it { should have_selector('ul.breadcrumb', text: "Submission \##{accepted_submission.id}") }
      it { should have_selector('ul.breadcrumb', text: "Referee #{@referee_assignment.referee_letter}") }
      
      it { should have_content(@referee_assignment.comments_for_editor) }
      it { should have_content(@referee_assignment.comments_for_author) }
      it { should have_content(@referee_assignment.recommendation) }
    end
    
    #update
    
    describe "unarchive a submission" do
      before do
        visit archive_path(accepted_submission)
        click_button('Unarchive')
      end
      
      it "sets archived to false" do
        expect(accepted_submission.reload.archived).to eq(false)
      end
      
      it "sets decision_approved to false" do
        expect(accepted_submission.reload.decision_approved).to eq(false)
      end
      
      it "emails the area editor and managing editors" do
        area_editor = accepted_submission.area_editor
        expect(deliveries).to include_email(subject_begins: 'Unarchived: ', to: managing_editor.email)
        expect(deliveries).to include_email(subject_begins: 'Unarchived: ', to: area_editor.email)                                    
        expect(SentEmail.all).to include_record(subject_begins: 'Unarchived: ', to: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Unarchived: ', to: area_editor.email)
      end
      
      it "redirects to submissions_path" do
        expect(current_path).to eq(submissions_path)
      end
    end
  end
  
  context "when logged in as area editor" do
    before { valid_sign_in(area_editor) }
    
    #index
    
    describe "index page" do
      before do
        accepted_submission.update_attributes(area_editor: area_editor)
        visit archives_path
      end
      
      it { should have_selector('ul.breadcrumb', text: 'Archives') }

      it { should have_link(accepted_submission.title) }        
      it { should_not have_link(desk_rejected_submission.title) }
    end
    
    #show
    
    describe "show archived submission page" do
      before do
        accepted_submission.update_attributes(area_editor: area_editor)
        visit archive_path(accepted_submission)
      end
      
      it { should have_selector('ul.breadcrumb', text: 'Archives') }
      it { should have_selector('ul.breadcrumb', text: "Submission \##{accepted_submission.id}") }
      it { should have_selector('h3', text: accepted_submission.title) }
      
      it { should_not have_button('Unarchive') }
      
      it { should have_content(accepted_submission.area_editor_comments_for_managing_editors) }
      it { should have_content(accepted_submission.area_editor_comments_for_author) }
      
      it "lists all non-canceled referee assignments" do
        accepted_submission.non_canceled_referee_assignments.each do |ra|
          expect(page).to have_content(ra.referee.full_name)
        end
      end
      
      it "links to completed referee reports" do
        report_path = archive_referee_assignment_path(accepted_submission, accepted_submission.referee_assignments.first)
        expect(page).to have_link('', href: report_path)
      end
    end
    
    describe "show archived submission's referee report page" do
      before do
        accepted_submission.update_attributes(area_editor: area_editor)
        visit archive_path(accepted_submission)
        @referee_assignment = accepted_submission.referee_assignments.first
        report_path = archive_referee_assignment_path(accepted_submission, @referee_assignment)
        report_link = find(:xpath, "//a[@href='" + report_path + "']")
        report_link.click   
      end
      
      it { should have_selector('ul.breadcrumb', text: 'Archives') }
      it { should have_selector('ul.breadcrumb', text: "Submission \##{accepted_submission.id}") }
      it { should have_selector('ul.breadcrumb', text: "Referee #{@referee_assignment.referee_letter}") }
      
      it { should have_content(@referee_assignment.comments_for_editor) }
      it { should have_content(@referee_assignment.comments_for_author) }
      it { should have_content(@referee_assignment.recommendation) }
    end
    
    describe "attempting to show archived submission not assigned" do
      before do
        accepted_submission.update_attributes(area_editor: FactoryGirl.create(:area_editor))
        visit archive_path(accepted_submission)
      end
      
      it "should redirect to security breach path" do
        current_path.should eq security_breach_path
      end
    end
    
    #update
    
    describe "unarchive a submission" do
      before { put archive_path(accepted_submission) }
      
      it "leaves the submission archived" do
        expect(accepted_submission.archived).to eq(true)
      end
      
      it "does not email the editors" do
        area_editor = accepted_submission.area_editor
        expect(deliveries).not_to include_email(subject_begins: 'Unarchived: ', to: managing_editor.email)
        expect(deliveries).not_to include_email(subject_begins: 'Unarchived: ', to: area_editor.email)                                    
        expect(SentEmail.all).not_to include_record(subject_begins: 'Unarchived: ', to: managing_editor.email)
        expect(SentEmail.all).not_to include_record(subject_begins: 'Unarchived: ', to: area_editor.email)
      end
      
      it "redirects to security_breach_path" do
        expect(response).to redirect_to(security_breach_path)
      end
    end

  end
  
  context "when logged in as author/referee" do
    before { valid_sign_in(user) }
    
    # index
    describe "index page" do
      before do
        visit archives_path
      end
      
      it "redirects to security breach" do
        expect(current_path).to eq(security_breach_path)
      end
    end
    
    # show
    describe "show archived submission page" do
      before do
        visit archive_path(accepted_submission)
      end
      
      it "redirects to security breach" do
        expect(current_path).to eq(security_breach_path)
      end
    end
    
    # update
    describe "unarchive a submission" do
      before { put archive_path(accepted_submission) }
      
      it "leaves the submission archived" do
        expect(accepted_submission.archived).to eq(true)
      end
      
      it "redirects to security_breach_path" do
        expect(response).to redirect_to(security_breach_path)
      end
    end
    
  end
  
  context "when not logged in" do
    # index
    describe "index page" do
      before { visit archives_path }
      
      it "redirects to signin" do
        expect(current_path).to eq(signin_path)
      end
    end
    
    # show
    describe "show page" do
      before { visit archive_path(accepted_submission) }
      
      it "redirects to signin" do
        expect(current_path).to eq(signin_path)
      end
    end
    
    # update
    describe "update" do
      before { put archive_path(accepted_submission) }
      
      it "redirects to signin" do
        expect(response).to redirect_to(signin_path)
      end
    end
  end
end
