require 'spec_helper'

describe "RevisionsController" do
  
  let!(:managing_editor) { create(:managing_editor) }
  let(:area_editor) { create(:area_editor) }
  let(:original_submission) { create(:major_revisions_requested_submission) }
  let(:author) { original_submission.author }
       
  context "when logged in as the author of the original submission" do
    before { valid_sign_in(author) }
    
    # new
    describe "new revised submission" do
      before { visit new_author_center_revision_path(original_submission) }
      
      it "displays a form for submitting a new revision" do
        expect(page).to have_content('Submit a revision')
        expect(page).to have_field('Title')
        expect(page).to have_field('File')
        expect(page).to have_button('Submit')
      end
    end
    
    # create
    describe "create a new revision" do
      before do
        visit new_author_center_revision_path(original_submission)
        fill_in 'Title', with: 'Revised Title'
        attach_file('File', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'))
        click_button 'Submit'
      end
      
      it "creates a revision" do
        expect(Submission.last.title).to eq('Revised Title')
        expect(Submission.last.original_id).to eq(original_submission.id)
      end
      
      it "redirects to the author center" do
        expect(current_path).to eq(author_center_index_path)
      end
      
      it "displays the revised submission in the list of submissions" do
        expect(page).to have_content(Submission.last.id)
        expect(page).to have_content('Revised Title')
      end
    end
  end
  
  shared_examples "no actions are accessible" do |redirect_path|
       
    # new
    describe "new resubmission" do
      before { visit new_author_center_revision_path(original_submission) }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # create
    describe "submit a new revision" do
      before do
        submission = { title: 'Some Title', manuscript_file: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf')) }
        post author_center_revisions_path(original_submission), submission: submission
      end
      
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
  end
  
  context "when logged in as a managing editor" do
    before { valid_sign_in(managing_editor) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when logged in as an area editor" do
    before { valid_sign_in(area_editor) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when logged in as some random user" do
    before { valid_sign_in(create(:user)) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when not logged in" do
    it_behaves_like "no actions are accessible", :signin_path
  end
end