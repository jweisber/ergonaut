require 'spec_helper'

describe "RefereeCenter pages" do
  
  let!(:managing_editor) { create(:managing_editor) }
  let(:submission) { create(:submission_assigned_to_area_editor) }
  let(:area_editor) { submission.area_editor }
  let(:referee) { create(:referee) }
  let(:assignment) { create(:referee_assignment, referee: referee, submission: submission) }

  let(:declined_assignment) { create(:declined_referee_assignment, referee: referee) }  
  let(:canceled_assignment) { create(:canceled_referee_assignment, referee: referee) }  
  let(:completed_assignment) { create(:completed_referee_assignment, referee: referee) }
  
  context "when logged in as an assigned referee" do
    before { valid_sign_in(referee) }
    
    # index
    describe "view index page" do
      before do
        assignment
        visit referee_center_index_path
      end
      
      it "lists active assignments" do
        expect(page).to have_content(submission.id.to_s )
        expect(page).to have_link(submission.title, href: edit_referee_center_path(assignment))
        expect(page).to have_link('Download', href: submission.manuscript_file)
      end
    end
    
    # edit
    describe "view edit page" do
      
      context "when not yet agreed" do
        before { visit edit_referee_center_path(assignment) }
        it "offers options to agree/decline" do
          expect(page).to have_field('referee_assignment_agreed_true')
          expect(page).to have_field('referee_assignment_agreed_false')
          expect(page).to have_field('referee_assignment_decline_comment')
          expect(page).to have_button('Submit')
        end
      end
      
      context "when already agreed" do
        before do
          assignment.agree!
          visit edit_referee_center_path(assignment)
        end
        
        it "offers a form for entering the report" do
          expect(page).to have_field('To the author')
          expect(page).to have_field('referee_assignment_attachment_for_author')
          expect(page).to have_field('To the editors')
          expect(page).to have_field('referee_assignment_attachment_for_editor')
          expect(page).to have_field('Recommendation')
          expect(page).to have_button('Submit')
        end
        
        context "when the submission is a revision" do
          before do
            submission = create(:first_revision_submission)
            assignment.update_attributes(submission: submission)
            
            @previous_submission = submission.previous_revision
            @previous_assignment = @previous_submission.referee_assignments.first
            @previous_assignment.update_attributes(referee: referee)

            visit edit_referee_center_path(assignment)
          end

          it "links to the previous version and report" do
            expect(page).to have_link "Previous version", href: @previous_submission.manuscript_file
            expect(page).to have_link "Previous report", href: referee_center_path(@previous_assignment)
          end
        
          it "disables the major/minor revisions options" do
            major_option = field_labeled('referee_assignment_recommendation').find(:xpath, ".//option[text() = '#{Decision::MAJOR_REVISIONS}']")
            minor_option = field_labeled('referee_assignment_recommendation').find(:xpath, ".//option[text() = '#{Decision::MINOR_REVISIONS}']")
            expect(major_option.disabled?).to be_true
            expect(minor_option.disabled?).to be_true
          end
        end
      end
    end

    # update
    describe "agree to the assignment" do
      before do
        visit edit_referee_center_path(assignment)
        choose('referee_assignment_agreed_true')
        click_button('Submit')
      end
      
      it "sets agreed to true" do
        assignment.reload
        expect(assignment.agreed).to be_true
      end
      
      it "redirects to the edit page" do
        expect(current_path).to eq(edit_referee_center_path(assignment))
      end
      
      it "notifies the area editor (cc managing editors) and sends a confirmation to the author (cc managing editors)" do
        expect(deliveries).to include_email(subject_begins: 'Referee Agreed', to: area_editor.email, cc: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Agreed', to: area_editor.email, cc: managing_editor.email)

        expect(deliveries).to include_email(subject_begins: 'Assignment Confirmation', to: referee.email, cc: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Assignment Confirmation', to: referee.email, cc: managing_editor.email)                                                
      end
    end
    
    describe "decline the assignment" do
      before do
        visit edit_referee_center_path(assignment)
        choose('referee_assignment_agreed_false')
        click_button('Submit')
      end
      
      it "sets agreed to false" do
        assignment.reload
        expect(assignment.agreed).to eq(false)
      end
      
      it "redirects to the edit page" do
        expect(current_path).to eq(referee_center_index_path)
      end
      
      it "notifies the editor" do
        expect(deliveries).to include_email(subject_begins: 'Referee Assignment Declined', to: area_editor.email, cc: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Assignment Declined', to: area_editor.email, cc: managing_editor.email)
      end
    end
    
    # preview
    describe "preview report" do
      before do
        assignment.comments_for_editor = 'Lorem ipsum dolor sit amet'
        assignment.comments_for_author = 'consectetur adipisicing elit'
        assignment.recommendation = Decision::MAJOR_REVISIONS
        assignment.save
        visit preview_referee_center_path(assignment)
      end
      
      it "displays the referee's comments and recommendation" do
        expect(page).to have_content('Comments for the editors:')
        expect(page).to have_content('Lorem ipsum dolor sit amet')
        expect(page).to have_content('Comments for the author:')
        expect(page).to have_content('consectetur adipisicing elit')
        expect(page).to have_content(Decision::MAJOR_REVISIONS)
      end
    end
    
    # complete
    describe "complete report" do
      
      before do
        @other_assignment = create(:referee_assignment, referee: referee, submission: submission)
        @other_assignment.agree!
        @second_other_assignment = create(:referee_assignment, referee: referee, submission: submission)
        @second_other_assignment.agree!
        assignment.agree!
        visit edit_referee_center_path(assignment)
        fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
        attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
        fill_in 'To the author', with: 'consectetur adipisicing elit'
        attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
        select Decision::MAJOR_REVISIONS, from: 'Recommendation'
        click_button 'Submit'
      end
      
      it "sets completed to true and completed_at to now" do
        assignment.reload
        expect(assignment.report_completed).to be_true
        expect(assignment.report_completed_at).to be > 10.seconds.ago
      end
      
      it "stores the comments" do
        assignment.reload
        expect(assignment.comments_for_editor).to eq('Lorem ipsum dolor sit amet')
        expect(assignment.comments_for_author).to eq('consectetur adipisicing elit')
      end
      
      it "uploads the files and attaches them to the assignment" do
        assignment.reload
        
        local_path = assignment.attachment_for_editor.current_path
        expect(local_path).not_to be_nil
        expect(File.exist?(local_path)).to be_true
        
        local_path = assignment.attachment_for_author.current_path
        expect(local_path).not_to be_nil
        expect(File.exist?(local_path)).to be_true
      end

      it "redirects to the index page" do
        expect(current_path).to eq(referee_center_index_path)
      end

      it "sends a thank you email (cc editors)" do
        area_editor = assignment.submission.area_editor
        expect(deliveries).to include_email(subject_begins: 'Thank you', to: referee.email, cc: area_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Thank you', to: referee.email, cc: area_editor.email)
        expect(deliveries).to include_email(subject_begins: 'Thank you', to: referee.email, cc: managing_editor.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Thank you', to: referee.email, cc: managing_editor.email)
      end

      it "notifies the area editor (cc managing editors)" do
        email = find_email(subject_begins: 'Referee Report Completed', to: area_editor.email, cc: managing_editor.email)
        
        expect(email).not_to be_nil
        expect(email.attachments.size).to eq(2)
        email.attachments.each do |attachment|
          expect(attachment.content_type).to start_with('application/pdf')
          expect(attachment.filename).to match(/Attachment\sfor.*\.pdf/)
        end
        
        expect(SentEmail.all).to include_record(subject_begins: 'Referee Report Completed', to: area_editor.email, cc: managing_editor.email)
      end

      context "when enough reports are complete, but one is still outstanding" do
        before do
          visit edit_referee_center_path(@other_assignment)
          fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
          attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          fill_in 'To the author', with: 'consectetur adipisicing elit'
          attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          select Decision::MAJOR_REVISIONS, from: 'Recommendation'
          click_button 'Submit'
        end

        it "sends an 'Enough Reports Complete' notification" do
          email = find_email(subject_begins: 'Enough Reports Complete', to: area_editor.email, cc: managing_editor.email)
          expect(email).not_to be_nil

          expect(SentEmail.all).to include_record(subject_begins: 'Enough Reports Complete', to: area_editor.email, cc: managing_editor.email)
        end

        it "doesn't send an 'All Reports Complete' notification" do
          email = find_email(subject_begins: 'All Reports Complete')
          expect(email).to be_nil
          expect(SentEmail.all).not_to include_record(subject_begins: 'All Reports Complete')
        end
      end

      context "when all reports are complete, but more are needed" do
        before do
          JournalSettings.current.update_attributes(number_of_reports_expected: 3)
          @second_other_assignment.cancel!
          visit edit_referee_center_path(@other_assignment)
          fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
          attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          fill_in 'To the author', with: 'consectetur adipisicing elit'
          attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          select Decision::MAJOR_REVISIONS, from: 'Recommendation'
          click_button 'Submit'
        end

        it "doesn't send an 'Enough Reports Complete' notification" do
          email = find_email(subject_begins: 'Enough Reports Complete', to: area_editor.email, cc: managing_editor.email)
          expect(email).to be_nil

          expect(SentEmail.all).not_to include_record(subject_begins: 'Enough Reports Complete', to: area_editor.email, cc: managing_editor.email)
        end

        it "sends an 'All Reports Complete' notification, with instructions to secure more reports" do
          email = find_email(subject_begins: 'All Reports Complete')
          expect(email).not_to be_nil
          expect(email.body).to match(/Unless you choose to reject this submission, please secure at least/)
          expect(SentEmail.all).to include_record(subject_begins: 'All Reports Complete')
        end
      end

      context "when the last outstanding assignment is completed" do
        before do
          visit edit_referee_center_path(@other_assignment)
          fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
          attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          fill_in 'To the author', with: 'consectetur adipisicing elit'
          attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          select Decision::MAJOR_REVISIONS, from: 'Recommendation'
          click_button 'Submit'
          
          visit edit_referee_center_path(@second_other_assignment)
          fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
          attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          fill_in 'To the author', with: 'consectetur adipisicing elit'
          attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
          select Decision::MAJOR_REVISIONS, from: 'Recommendation'
          click_button 'Submit'
        end

        it "sends an 'All Reports Complete' notification, with instructions to enter a decision" do
          email = find_email(subject_begins: 'All Reports Complete', to: area_editor.email, cc: managing_editor.email)
          expect(email).not_to be_nil
          expect(email.body).to match(/Please enter a decision within/)
          expect(SentEmail.all).to include_record(subject_begins: 'All Reports Complete', to: area_editor.email, cc: managing_editor.email)
        end
      end

    end
    
    # show
    describe "show report" do
      before do
        assignment = create(:completed_referee_assignment, referee: referee)
        @attachment_for_editor = assignment.attachment_for_editor
        @attachment_for_author = assignment.attachment_for_author
        visit referee_center_path(assignment)
      end

      it "displays the report" do
        expect(page).to have_content('To the editors')
        expect(page).to have_content('Lorem ipsum dolor sit amet')
        expect(page).to have_link('', href: @attachment_for_editor.url)
        expect(page).to have_content('To the author')
        expect(page).to have_content('Duis aute irure')
        expect(page).to have_link('', href: @attachment_for_author.url)
        expect(page).to have_content(Decision::MAJOR_REVISIONS)
      end

      it "has working link to attachment for editor" do
        find(:xpath, "//a[@href='#{@attachment_for_editor.url}']").click
        expect(page.response_headers['Content-Type']).to eq('application/pdf')
      end

      it "has working link to attachment for author" do
        find(:xpath, "//a[@href='#{@attachment_for_author.url}']").click
        expect(page.response_headers['Content-Type']).to eq('application/pdf')
      end
    end

    # archives
    describe "view archived assignments" do
      before do
        declined_assignment
        canceled_assignment
        completed_assignment
        visit archives_referee_center_index_path
      end
      
      it "lists declined assignments" do
        expect(page).to have_content(declined_assignment.submission.id.to_s)
        expect(page).to have_content(declined_assignment.submission.title)
      end
      
      it "lists canceled assignments" do
        expect(page).to have_content(canceled_assignment.submission.id.to_s)
        expect(page).to have_content(canceled_assignment.submission.title)
      end
      
      it "lists completed assignments" do
        expect(page).to have_content(completed_assignment.submission.id.to_s)
        expect(page).to have_link(completed_assignment.submission.title, href: referee_center_path(completed_assignment))
      end
    end 
  end
  
  shared_examples "no assignment-specific actions are accessible" do |redirect_path|
    
    # edit 
    describe "view edit page" do
      before { get edit_referee_center_path(assignment) }   
      it { should bounce_to(send(redirect_path)) }
    end
    
    # update
    describe "update referee assignment to agreed" do
      before do
        assignment.agreed = true
        put referee_center_path(assignment), referee_assignment: assignment
      end
      
      it "leaves agreed nil" do
        assignment.reload
        expect(assignment.agreed).to be_nil
      end
      
      it { should bounce_to(send(redirect_path)) }
    end
    
    # preview
    describe "preview report" do
      before { get preview_referee_center_path(assignment) }   
      it { should bounce_to(send(redirect_path)) }
    end
    
    # complete
    describe "complete report" do
      before { get complete_referee_center_path(assignment) }
      
      it "leaves report_completed false" do
        assignment.reload
        expect(assignment.report_completed).to eq(false)
      end
      
      it { should bounce_to(send(redirect_path)) }
    end
    
    # show
    describe "show referee assignment" do
      before { get referee_center_path(assignment) }      
      it { should bounce_to(send(redirect_path)) }
    end
  end
  
  shared_examples "no non-assignment-specific actions are accessible" do |redirect_path|
    
    # index
    describe "view index page" do
      before { get referee_center_index_path }   
      it { should bounce_to(send(redirect_path)) }
    end

    # archives
    describe "view archived assignments" do
      before { get archives_referee_center_index_path }     
      it { should bounce_to(send(redirect_path)) }
    end 
  end
  
  context "when logged in as a managing editor" do
    before { valid_sign_in(managing_editor) }
    it_behaves_like "no assignment-specific actions are accessible", :security_breach_path
    it_behaves_like "no non-assignment-specific actions are accessible", :security_breach_path
  end
  
  context "when logged in as the assigned area editor" do
    before { valid_sign_in(area_editor) }
    it_behaves_like "no assignment-specific actions are accessible", :security_breach_path
    it_behaves_like "no non-assignment-specific actions are accessible", :security_breach_path
  end
  
  context "when logged in as an unrelated referee" do
    before { valid_sign_in(create(:referee)) }
    it_behaves_like "no assignment-specific actions are accessible", :security_breach_path
  end
  
  context "when not logged in" do
    it_behaves_like "no assignment-specific actions are accessible", :signin_path
    it_behaves_like "no non-assignment-specific actions are accessible", :signin_path
  end
end