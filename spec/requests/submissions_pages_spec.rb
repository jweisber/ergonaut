require 'spec_helper'

describe "SubmissionsPages" do
  
  let!(:managing_editor) { create(:managing_editor) }
  let(:area_editor) { create(:area_editor) }
  
  let(:new_submission) { create(:submission) }
  let(:submission_sent_for_review_without_area_editor) { create(:submission_sent_for_review_without_area_editor) }
  let(:submission_assigned_to_area_editor) { create(:submission_assigned_to_area_editor) }
  let(:submission_assigned_to_area_editor_overdue_for_internal_review) { create(:submission_assigned_to_area_editor_overdue_for_internal_review) }
  let(:submission_sent_out_for_review) { create(:submission_sent_out_for_review) }
  let(:submission_with_two_agreed_referee_assignments) { create(:submission_with_two_agreed_referee_assignments) }
  let(:submission_with_one_completed_referee_assignment) { create(:submission_with_one_completed_referee_assignment) }
  let(:submission_withdrawn) { create(:submission_withdrawn) }  
  let(:submission_with_two_completed_referee_assignments) { create(:submission_with_two_completed_referee_assignments) }
  let(:submission_with_major_revisions_decision_not_yet_approved) { create(:submission_with_major_revisions_decision_not_yet_approved) }
  let(:desk_rejected_submission) { create(:desk_rejected_submission) }
  let(:rejected_after_review_submission) { create(:rejected_after_review_submission) }
  let(:major_revisions_requested_submission) { create(:major_revisions_requested_submission) }
  let(:minor_revisions_requested_submission) { create(:minor_revisions_requested_submission) }
  let(:first_revision_submission) { create(:first_revision_submission) }
  let(:second_revision_submission) { create(:second_revision_submission) }
  
  let(:active_subumissions) do
    [ new_submission,
      submission_sent_for_review_without_area_editor,
      submission_assigned_to_area_editor,
      submission_assigned_to_area_editor_overdue_for_internal_review,
      submission_sent_out_for_review,
      submission_with_two_agreed_referee_assignments,
      submission_with_one_completed_referee_assignment,
      submission_with_two_completed_referee_assignments,
      submission_with_major_revisions_decision_not_yet_approved,
      first_revision_submission,
      second_revision_submission ]
  end
  
  let(:inactive_submissions) do
    [ submission_withdrawn,
      desk_rejected_submission,
      rejected_after_review_submission,
      major_revisions_requested_submission,
      minor_revisions_requested_submission ]
  end
  
  context "when signed in as a managing editor" do
    before { valid_sign_in(managing_editor) }
    
    # index
    describe "index page" do
      before do
        active_subumissions
        inactive_submissions
        visit submissions_path
      end
      
      it "does not list inactive submissions" do
        inactive_submissions.each do |submission|
          expect(page).not_to have_link(submission.title)
        end
      end
      
      it "lists all active submissions, as links" do
        active_subumissions.each do |submission|
          expect(page).to have_link(submission.title, href: submission_path(submission))
        end
      end
      
      it "lists information about each active submission" do
        active_subumissions.each do |submission|
          expect(page).to have_content(submission.date_submitted_pretty)
          expect(page).to have_content(submission.area.short_name)
          expect(page).to have_content(submission.area_editor.full_name) if submission.area_editor
          expect(page).to have_content(submission.display_status_for_editors)
        end
      end
      
      it "lists each author's name" do
        active_subumissions.each do |submission|
          expect(page).to have_content(submission.author.full_name)
        end
      end
      
      it "links to the archives" do
        expect(page).to have_link('Archives', archives_path)
      end
    end
  
    # show
    describe "show page" do
      before do
        @submission = submission_with_major_revisions_decision_not_yet_approved
        visit submission_path(@submission)
      end
      
      it "displays the author's name" do
        expect(page).to have_content(@submission.author.full_name)
      end
      
      it "displays information about the submission" do
        expect(page).to have_link(@submission.title, href: @submission.manuscript_file)
        expect(page).to have_link('', href: edit_manuscript_file_submission_path(@submission))
        expect(page).to have_content(@submission.area.name)
        expect(page).to have_link('Email log', href: submission_sent_emails_path(@submission))
        expect(page).to have_link('Edit', href: edit_submission_path(@submission))
        expect(page).to have_content(@submission.area_editor.full_name)
        expect(page).to have_content(@submission.area_editor_comments_for_managing_editors)
        expect(page).to have_content(@submission.area_editor_comments_for_author)
        expect(page).to have_content(@submission.display_status_for_editors)
        expect(page).to have_content(@submission.decision)
      end
      
      it "displays information about the referee assignments" do
        @submission.referee_assignments.each do |assignment|
          expect(page).to have_link('Delete', href: submission_referee_assignment_path(@submission, assignment))
          expect(page).to have_content(assignment.referee.full_name)
          expect(page).to have_content(assignment.date_assigned_pretty)
          expect(page).to have_content(assignment.date_agreed_pretty)
          expect(page).to have_content(assignment.date_completed_pretty)
          expect(page).to have_content(assignment.recommendation)
          expect(page).to have_link('', href: submission_referee_assignment_path(@submission, assignment))
          expect(page).to have_link('Add', href: new_submission_referee_assignment_path(@submission))
          expect(page).not_to have_link('Yes')
          expect(page).not_to have_link('No')
        end
      end
      
      it "cancels a referee assignment when 'Delete' is clicked" do
        assignment = @submission.referee_assignments.sample
        delete_link = first(:link, 'Delete', href: submission_referee_assignment_path(@submission, assignment))
        delete_link.click
        expect(assignment.reload).to be_canceled
        expect(page).not_to have_content(assignment.referee.full_name)
      end
      
      context "when there are pending and declined referee assignments" do
        before do
          @pending_assignment = RefereeAssignment.create(referee: create(:referee), 
                                                         submission: @submission, 
                                                         custom_email_opening: 'Hey you')
          @declined_assignment = RefereeAssignment.create(referee: create(:referee),  
                                                          submission: @submission, 
                                                          custom_email_opening: 'Hey you', 
                                                          agreed: false,
                                                          decline_comment: 'Ask someone else.')
          visit submission_path(submission_with_major_revisions_decision_not_yet_approved)
        end
        
        it "has working links for agree/decline-on-behalf-of" do
          expect(page).to have_link('Yes', href: agree_on_behalf_submission_referee_assignment_path(@submission, @pending_assignment))
          expect(page).to have_link('No', href: decline_on_behalf_submission_referee_assignment_path(@submission, @pending_assignment))
        end
        
        it "has working tooltips for the agree/decline-on-behalf-of links", js: true do
          expect(page).not_to have_content('agreed in personal communication')
          find_link('Yes').hover
          expect(page).to have_content('agreed in personal communication')
          
          expect(page).not_to have_content('declined in personal communication')
          find_link('No').hover
          expect(page).to have_content('declined in personal communication')
        end
      
        it "has a decline-comment link" do
          expect(page).to have_xpath("//a[@data-content='#{@declined_assignment.decline_comment}']")
        end
      end
      
      context "when the submission is a revision" do
        before do
          @submission = first_revision_submission
          @previous = @submission.previous_revision
          visit submission_path(@submission)
        end
        
        it "links to the original and displays the date resubmitted" do
          expect(page).to have_link("Submission \##{@previous.id}", href: submission_path(@previous))
          expect(page).to have_content("Resubmitted #{@previous.date_submitted_pretty}")
        end
      end
      
      context "when the submission is archived" do
        before do
          @submission.update_attributes(archived: true)
          visit submission_path(@submission)
        end
        
        it "redirects to the archives" do
          expect(current_path).to eq(archive_path(@submission))
        end
      end
    end
  
    # edit
    describe "edit page" do
      before do
        @submission = submission_with_major_revisions_decision_not_yet_approved
        visit edit_submission_path(@submission)
      end
      
      it "displays the author's name" do
        expect(page).to have_content(@submission.author.full_name)
      end
      
      it "displays basic information about the submission" do
        expect(page).to have_link(@submission.title, href: @submission.manuscript_file)
        expect(page).to have_content(@submission.area.name)
        expect(page).to have_content(@submission.date_submitted_pretty)
      end
      
      it "provides a form for internal review of the submission" do
        expect(page).to have_select('submission_user_id')
        expect(page).to have_field('submission_area_editor_comments_for_managing_editors')
        expect(page).to have_field('submission_area_editor_comments_for_author')
        expect(page).to have_select('submission_decision')
        expect(page).to have_field('submission_decision_approved')
        expect(page).to have_link('Cancel', href: submission_path(@submission))
        expect(page).to have_button('Save')
      end
      
      context "when the submission is a revision" do
        before do
          @submission = create(:first_revision_submission)
          visit edit_submission_path(@submission)
        end

        it "links to the previous version" do
          previous_revision = @submission.previous_revision
          expect(page).to have_link "Submission \##{previous_revision.id}", href: submission_path(previous_revision)
        end
        
        it "disables the major/minor revisions options" do
          major_option = field_labeled('submission_decision').find(:xpath, ".//option[text() = '#{Decision::MAJOR_REVISIONS}']")
          minor_option = field_labeled('submission_decision').find(:xpath, ".//option[text() = '#{Decision::MINOR_REVISIONS}']")
          expect(major_option.disabled?).to be_true
          expect(minor_option.disabled?).to be_true
        end
      end
    end
  
    # update
    describe "update" do
      before do
        area_editor
        visit edit_submission_path(new_submission)
      end
      
      context "assigning an area editor" do
        before do
          select area_editor.full_name, from: 'submission_user_id'
          click_button 'Save'
        end
        
        it "assigns the area editor" do
          expect(new_submission.reload.area_editor).to eq(area_editor)
        end
        
        it "emails a notification to the area editor" do
          expect(deliveries).to include_email(subject_begins: 'New Assignment', to: area_editor.email, cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'New Assignment', to: area_editor.email, cc: managing_editor.email)
        end
        
        it "redirects to the submission's show page" do
          expect(current_path).to eq(submission_path(new_submission))
        end
      end
      
      context "switching area editors" do
        before do
          visit edit_submission_path(submission_assigned_to_area_editor)
          @old_editor = submission_assigned_to_area_editor.area_editor
          select area_editor.full_name, from: 'submission_user_id'
          click_button 'Save'
        end
        
        it "assigns the area editor" do
          expect(submission_assigned_to_area_editor.reload.area_editor).to eq(area_editor)
        end
        
        it "sends notifications to both area_editors" do
          expect(deliveries).to include_email(subject_begins: 'New Assignment', to: area_editor.email, cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'New Assignment', to: area_editor.email, cc: managing_editor.email)
          expect(deliveries).to include_email(subject_begins: 'Assignment Canceled', to: @old_editor.email, cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Assignment Canceled', to: @old_editor.email, cc: managing_editor.email)                                          
        end
        
        it "redirects to the submission's show page" do
          expect(current_path).to eq(submission_path(submission_assigned_to_area_editor))
        end
      end
      
      context "updating the comments" do
        before do
          fill_in 'submission_area_editor_comments_for_managing_editors', with: 'Lorem ipsum dolor sit amet'
          fill_in 'submission_area_editor_comments_for_author', with: 'consectetur adipiscing elit'
          click_button 'Save'
        end
        
        it "updates the submission's comments" do
          new_submission.reload
          expect(new_submission.area_editor_comments_for_managing_editors).to eq('Lorem ipsum dolor sit amet')
          expect(new_submission.area_editor_comments_for_author).to eq('consectetur adipiscing elit')
        end
        
        it "redirects to the submission's show page" do
          expect(current_path).to eq(submission_path(new_submission))
        end
      end
      
      context "entering a decision" do
        before do
          n = JournalSettings.number_of_reports_expected
          n.times { create(:completed_referee_assignment, submission: new_submission) }
                    
          select Decision::MAJOR_REVISIONS, from: 'submission_decision'
          click_button 'Save'
        end
        
        it "updates the submission's decision" do
          expect(new_submission.reload.decision).to eq(Decision::MAJOR_REVISIONS)
        end
        
        it "emails the managing editors" do
          expect(deliveries).to include_email(subject_begins: 'Decision Needs Approval', to: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Decision Needs Approval', to: managing_editor.email)
        end
        
        it "redirects to the show page" do
          expect(current_path).to eq(submission_path(new_submission))
        end
      end
      
      context "approving a decision" do
        
        context "decision = '#{Decision::REJECT}'" do
          before do
            select area_editor.full_name, from: 'submission_user_id'
            click_button 'Save'
            click_link 'Edit'
            select Decision::REJECT, from: 'submission_decision'
            check 'submission_decision_approved'
            click_button 'Save'
          end
        
          it "sets decision_approved and archived to true" do
            new_submission.reload
            expect(new_submission.decision).to eq(Decision::REJECT)
            expect(new_submission.decision_approved).to be_true
            expect(new_submission.archived).to eq(true)
          end
          
          it "notifies the author (cc managing editors)" do
            expect(deliveries).to include_email(subject_begins: 'Decision Regarding Submission', to: new_submission.author.email, cc: managing_editor.email)
            expect(SentEmail.all).to include_record(subject_begins: 'Decision Regarding Submission', to: new_submission.author.email, cc: managing_editor.email)
          end
          
          it "notifies the area editor" do
            expect(deliveries).to include_email(subject_begins: 'Decision Approved', to: area_editor.email, cc: managing_editor.email)
            expect(SentEmail.all).to include_record(subject_begins: 'Decision Approved', to: area_editor.email, cc: managing_editor.email)
          end
        end
        
        context "decision = '#{Decision::MAJOR_REVISIONS}'" do
          before do
            visit edit_submission_path(submission_with_major_revisions_decision_not_yet_approved)
            check 'submission_decision_approved'
            click_button 'Save'
          end
        
          it "sets decision_approved and archived to true " do
            submission_with_major_revisions_decision_not_yet_approved.reload
            expect(submission_with_major_revisions_decision_not_yet_approved.decision_approved).to be_true
            expect(submission_with_major_revisions_decision_not_yet_approved.archived).to eq(true)
          end
          
          it "notifies the author (cc managing editors)" do
            author = submission_with_major_revisions_decision_not_yet_approved.author
            email = find_email(subject_begins: 'Decision Regarding Submission', to: author.email, cc: managing_editor.email)
            
            expect(email).not_to be_nil
            expect(email.attachments.size).to eq(2)
            email.attachments.each do |attachment|
              expect(attachment.content_type).to start_with('application/pdf')
              expect(attachment.filename).to match(/Referee\s[A-Z]\.pdf/)
            end
            
            expect(SentEmail.all).to include_record(subject_begins: 'Decision Regarding Submission', to: author.email, cc: managing_editor.email)
          end
          
          it "notifies the area editor (cc managing editors)" do
            area_editor = submission_with_major_revisions_decision_not_yet_approved.area_editor
            expect(deliveries).to include_email(subject_begins: 'Decision Approved', to: area_editor.email, cc: managing_editor.email)
            expect(SentEmail.all).to include_record(subject_begins: 'Decision Approved', to: area_editor.email, cc: managing_editor.email)
          end
          
          it "notifies the referees (cc editors)" do
            submission = submission_with_major_revisions_decision_not_yet_approved
            area_editor = submission.area_editor
            
            submission.referee_assignments.where(report_completed: true).each do |assignment|
              email = find_email(subject_begins: 'Outcome & Thank You', to: assignment.referee.email, cc: [area_editor.email, managing_editor.email])
              expect(email).not_to be_nil
              expect(email.attachments.size).to eq(1)
              email.attachments.each do |attachment|
                expect(attachment.content_type).to start_with('application/pdf')
                expect(attachment.filename).to match(/Referee\s[A-Z]\.pdf/)
              end              

              expect(SentEmail.all).to include_record(subject_begins: 'Outcome & Thank You', to: assignment.referee.email, cc: area_editor.email)
              expect(SentEmail.all).to include_record(subject_begins: 'Outcome & Thank You', to: assignment.referee.email, cc: managing_editor.email)
            end
          end
        end
      end
    end
  
    # download
    describe "download" do
      before do
        visit submission_path(new_submission)
        click_link(new_submission.title)
      end
      
      it "downloads a pdf" do
        expect(page.response_headers['Content-Type']).to eq('application/pdf')
      end
    end
    
    # edit_manuscript_file
    describe "edit manuscript file" do
      before { visit edit_manuscript_file_submission_path(new_submission) }

      it "has a form for uploading a new manuscript file" do
        expect(page).to have_content('Replace manuscript')
        expect(page).to have_content('Replace with')
        expect(page).to have_button('Submit')
      end
    end
    
    # update_manuscript_file
    describe "update manuscript file" do
      context "with a file attached" do
        before do
          visit edit_manuscript_file_submission_path(new_submission)
          attach_file 'submission_manuscript_file', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf')
          click_button 'Submit'
        end

        it "renders the show page and flashes success" do
          expect(page).to have_success_message('Manuscript file replaced')
        end
      
        it "copies the old manuscript file to manuscript.ext.bak" do
          path_to_copy = new_submission.manuscript_file.current_path + '.bak'
          expect(File.exists?(path_to_copy)).to be_true
        end
      
        it "saves the new file to manuscript.ext" do
          # how to test this?
        end
      end
      
      context "without a file attached" do
        before do
          visit edit_manuscript_file_submission_path(new_submission)
          click_button 'Submit'
        end
        
        it "re-renders the page and flashes an error" do
          expect(page).to have_content('Replace manuscript')
          expect(page).to have_error_message('Did you forget to choose a new file?')
        end
        
        it "does not copy the original file to manuscript.ext.bak" do
          path_to_copy = new_submission.manuscript_file.current_path + '.bak'
          expect(File.exists?(path_to_copy)).to be_false
        end
      end
    end
  end
  
  context "when signed in as an area editor" do
    before { valid_sign_in(area_editor) }
    
    # index
    describe "index page" do
      before do
        active_subumissions[0,5].each do |submission|
          submission.update_attributes(area_editor: area_editor)
        end
        inactive_submissions
        visit submissions_path
      end
      
      it "does not list inactive submissions" do
        inactive_submissions.each do |submission|
          expect(page).not_to have_link(submission.title)
        end
      end
      
      it "lists all this area editor's active submissions, as links" do
        active_subumissions[0,5].each do |submission|
          expect(page).to have_link(submission.title, href: submission_path(submission))
        end
      end
      
      it "doesn't list other editors' active submissions" do
        active_subumissions.from(5).each do |submission|
          expect(page).not_to have_content(submission.title)
        end
      end
      
      it "lists information about each active submission" do
        active_subumissions[0,5].each do |submission|
          expect(page).to have_content(submission.date_submitted_pretty)
          expect(page).to have_content(submission.area.short_name)
          expect(page).to have_content(submission.area_editor.full_name) if submission.area_editor
          expect(page).to have_content(submission.display_status_for_editors)
        end
      end
      
      it "links to the archives" do
        expect(page).to have_link('Archives', archives_path)
      end
    end
  
    # show
    describe "show page" do
      before do
        @submission = submission_with_major_revisions_decision_not_yet_approved
        @submission.update_attributes(area_editor: area_editor)
        visit submission_path(@submission)
      end
      
      it "doesn't display the author's name" do
        expect(page).not_to have_content(@submission.author.full_name)
      end
      
      it "displays information about the submission" do
        expect(page).to have_link(@submission.title, href: @submission.manuscript_file)
        expect(page).to have_content(@submission.area.name)
        expect(page).to have_link('Editor\'s guide', href: guide_path)
        expect(page).to have_link('Edit', href: edit_submission_path(@submission))
        expect(page).to have_content(@submission.area_editor.full_name)
        expect(page).to have_content(@submission.area_editor_comments_for_managing_editors)
        expect(page).to have_content(@submission.area_editor_comments_for_author)
        expect(page).to have_content(@submission.display_status_for_editors)
        expect(page).to have_content(@submission.decision)
        expect(page).to have_link('Email log', href: submission_sent_emails_path(@submission))
      end
      
      it "displays information about the referee assignments" do
        @submission.referee_assignments.each do |assignment|
          expect(page).to have_link('Delete', href: submission_referee_assignment_path(@submission, assignment))
          expect(page).to have_content(assignment.referee.full_name)
          expect(page).to have_content(assignment.date_assigned_pretty)
          expect(page).to have_content(assignment.date_agreed_pretty)
          expect(page).to have_content(assignment.date_completed_pretty)
          expect(page).to have_content(assignment.recommendation)
          expect(page).to have_link('', href: submission_referee_assignment_path(@submission, assignment))
          expect(page).to have_link('Add', href: new_submission_referee_assignment_path(@submission))
          expect(page).not_to have_link('Yes')
          expect(page).not_to have_link('No')
        end
      end
      
      it "cancels a referee assignment when 'Delete' is clicked" do
        assignment = @submission.referee_assignments.sample
        delete_link = first(:link, 'Delete', href: submission_referee_assignment_path(@submission, assignment))
        delete_link.click
        expect(assignment.reload).to be_canceled
        expect(page).not_to have_content(assignment.referee.full_name)
      end
      
      context "when there are pending and declined referee assignments" do
        before do
          @pending_assignment = RefereeAssignment.create(referee: create(:referee), 
                                                         submission: @submission, 
                                                         custom_email_opening: 'Hey you')
          @declined_assignment = RefereeAssignment.create(referee: create(:referee),  
                                                          submission: @submission, 
                                                          custom_email_opening: 'Hey you', 
                                                          agreed: false,
                                                          decline_comment: 'Ask someone else.')
          visit submission_path(submission_with_major_revisions_decision_not_yet_approved)
        end
        
        it "has working links for agree/decline-on-behalf-of" do
          expect(page).to have_link('Yes', href: agree_on_behalf_submission_referee_assignment_path(@submission, @pending_assignment))
          expect(page).to have_link('No', href: decline_on_behalf_submission_referee_assignment_path(@submission, @pending_assignment))
        end
      
        it "has working tooltips for the agree/decline-on-behalf-of links", js: true do
          expect(page).not_to have_content('agreed in personal communication')
          find_link('Yes').hover
          expect(page).to have_content('agreed in personal communication')
          
          expect(page).not_to have_content('declined in personal communication')
          find_link('No').hover
          expect(page).to have_content('declined in personal communication')
        end
        
        it "has a decline-comment link" do
          expect(page).to have_xpath("//a[@data-content='#{@declined_assignment.decline_comment}']")
        end
      end
      
      context "when the submission is a revision" do
        before do
          @submission = first_revision_submission
          @original = @submission.original
          @submission.update_attributes(area_editor: @original.area_editor)
          valid_sign_in(@original.area_editor)
          visit submission_path(@submission)
        end
        
        it "links to the original and displays the date resubmitted" do
          expect(page).to have_link("Submission \##{@original.id}", href: submission_path(@original))
          expect(page).to have_content("Resubmitted #{@original.date_submitted_pretty}")
        end
      end
      
      context "when the submission is archived" do
        before do
          @submission.update_attributes(archived: true)
          visit submission_path(@submission)
        end
        
        it "redirects to the archives" do
          expect(current_path).to eq(archive_path(@submission))
        end
      end
    end
  
    # edit
    describe "edit page" do
      before do
        @submission = submission_with_major_revisions_decision_not_yet_approved
        @submission.update_attributes(area_editor: area_editor)
        visit edit_submission_path(@submission)
      end
      
      it "doesn't display the author's name" do
        expect(page).not_to have_content(@submission.author.full_name)
      end
      
      it "displays basic information about the submission" do
        expect(page).to have_link(@submission.title, href: @submission.manuscript_file)
        expect(page).to have_content(@submission.area.name)
        expect(page).to have_content(@submission.date_submitted_pretty)
      end
      
      it "provides a form for internal review of the submission" do
        expect(page).to have_field('submission_area_editor_comments_for_managing_editors')
        expect(page).to have_field('submission_area_editor_comments_for_author')
        expect(page).to have_select('submission_decision')
        expect(page).to have_link('Cancel', href: submission_path(@submission))
        expect(page).to have_button('Save')
      end
    end
  
    # update
    describe "update" do
      before do
        new_submission.update_attributes(area_editor: area_editor)
        visit edit_submission_path(new_submission)
      end
      
      context "updating the comments" do
        before do
          fill_in 'submission_area_editor_comments_for_managing_editors', with: 'Lorem ipsum dolor sit amet'
          fill_in 'submission_area_editor_comments_for_author', with: 'consectetur adipiscing elit'
          click_button 'Save'
        end
        
        it "updates the submission's comments" do
          new_submission.reload
          expect(new_submission.area_editor_comments_for_managing_editors).to eq('Lorem ipsum dolor sit amet')
          expect(new_submission.area_editor_comments_for_author).to eq('consectetur adipiscing elit')
        end
        
        it "redirects to the submission's show page" do
          expect(current_path).to eq(submission_path(new_submission))
        end
      end
      
      context "entering a decision" do
        before do
          n = JournalSettings.number_of_reports_expected
          n.times { create(:completed_referee_assignment, submission: new_submission) }
                    
          select Decision::MAJOR_REVISIONS, from: 'submission_decision'
          click_button 'Save'
        end
        
        it "updates the submission's decision" do
          expect(new_submission.reload.decision).to eq(Decision::MAJOR_REVISIONS)
        end
        
        it "emails the managing editors (cc area editor)" do
          expect(deliveries).to include_email(subject_begins: 'Decision Needs Approval', to: managing_editor.email, cc: area_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Decision Needs Approval', to: managing_editor.email, cc: area_editor.email)
        end
        
        it "redirects to the show page" do
          expect(current_path).to eq(submission_path(new_submission))
        end
      end
    end
  
    # download
    describe "download" do
      context "assigned submission" do
        before do
          new_submission.update_attributes(area_editor: area_editor)
          visit submission_path(new_submission)
          click_link(new_submission.title)
        end
      
        it "downloads a pdf" do
          expect(page.response_headers['Content-Type']).to eq('application/pdf')
        end
      end
      
      context "submission not assigned to" do
        before do
          visit new_submission.manuscript_file.url
        end
      
        it "redirects to security breach" do
          expect(current_path).to eq(security_breach_path)
        end
      end
    end
    
    # edit_manuscript_file
    describe "edit manuscript file page" do
      before do
        new_submission.update_attributes(area_editor: area_editor)
        visit edit_manuscript_file_submission_path(new_submission)
      end
      
      it "redirects to security breach" do
        expect(current_path).to eq(security_breach_path)
      end
    end
    
    # update_manuscript_file
    describe "update manuscript file page" do
      before do
        new_submission.update_attributes(area_editor: area_editor)
        put update_manuscript_file_submission_path(new_submission)
      end
      
      it "redirects to security breach" do
        expect(response).to redirect_to(security_breach_path)
      end
    end
  end
  
  shared_examples_for "no standard actions are accessible" do |redirect_path|
    
    # index
    describe "index page" do
      before { visit submissions_path }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # show
    describe "show page" do
      before { visit submission_path(new_submission) }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # edit
    describe "edit page" do
      before { visit edit_submission_path(new_submission) }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # update
    describe "update" do
      before do
        put submission_path(new_submission)
      end
      
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
    
    # edit_manuscript_file
    describe "edit manuscript file page" do
      before { visit edit_manuscript_file_submission_path(new_submission) }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # update_manuscript_file
    describe "update manuscript file page" do
      before do
        put update_manuscript_file_submission_path(new_submission)
      end
      
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
  end
  
  context "when logged in as an author/referee" do
    before { valid_sign_in(new_submission.author) }
    
    it_behaves_like "no standard actions are accessible", :security_breach_path
    
    # download
    describe "download" do
      context "when downloading own submission" do
        before { visit new_submission.manuscript_file.url }
        
        it "downloads the pdf" do
          expect(page.response_headers['Content-Type']).to eq('application/pdf')
        end
      end
      
      context "when trying to download someone else's submission" do
        before do
          other_submission = create(:submission)
          visit other_submission.manuscript_file.url
        end
        
        it "redirects to security breach" do
          expect(current_path).to eq(security_breach_path)
        end
      end
    end
  end
  
  context "when not logged in" do
    it_behaves_like "no standard actions are accessible", :signin_path
    
    # download
    describe "download" do
      before { visit new_submission.manuscript_file.url }
      
      it "redirects to signin" do
        expect(current_path).to eq(signin_path)
      end
    end
  end
end