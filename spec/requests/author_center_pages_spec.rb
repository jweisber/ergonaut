require 'spec_helper'

describe "Author Center" do
  
  let(:user) { create(:user) }
  let(:area_editor) { create(:area_editor) }
  let!(:managing_editor) { create(:managing_editor) }
  
  let!(:desk_rejected_submission) { create(:desk_rejected_submission) }
  let!(:accepted_submission) { create(:accepted_submission) }
  
  subject { page }

  context "when logged in as author/referee" do
    before { valid_sign_in(user) }
    
    # new
    describe "new submission page" do
      before { visit new_author_center_path }
      
      it "offers a form for submitting a paper" do
        expect(page).to have_content('Submit a paper')
        expect(page).to have_field('Title')
        expect(page).to have_field('Area')
        expect(page).to have_field('File')
        expect(page).to have_button('Submit')
      end
    end
    
    # create
    describe "creating a submission" do
      before { visit new_author_center_path }
      
      context "with valid inputs" do
        before do
          fill_in 'Title', with: 'Valid Test Submission'
          attach_file('File', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'))
          click_button 'Submit'
        end
        
        it { should have_success_message('received') }
        
        it "lists the user's submissions" do
          for sub in user.submissions do
            expect(page).to have_content(sub.title)
          end
        end
        
        it "has a working link to the manuscript" do
          click_link 'Valid Test Submission'
          expect(page.response_headers['Content-Type']).to eq 'application/pdf'
        end
        
        it "emails the managing editors" do
          expect(deliveries).to include_email(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Valid Test Submission')
          expect(SentEmail.all).to include_record(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Valid Test Submission')
        end
      end
      
      context "with a missing title" do
        before do
          reset_email
          attach_file('File', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'))
          click_button 'Submit'
        end
        
        it "doesn't create a new submission" do
          expect(user.reload.submissions).to be_empty
        end
        
        it "displays alert and describes error" do
          expect(page).to have_error_message('error')
          expect(page).to have_content 'can\'t be blank'
        end
        
        it "re-renders the page for a new submission" do
          expect(page).to have_field 'Title'
        end
        
        it "doesn't email the managing editors" do
          expect(deliveries).not_to include_email(subject_begins: 'New Submission', to: managing_editor.email)
        end
      end
      
      context "with no file attached" do
        before do
          fill_in 'Title', with: 'Some Clever Title'
          click_button 'Submit'
        end
        
        it "doesn't create a new submission" do
          expect(user.reload.submissions).to be_empty
        end
        
        it "displays alert and describes error" do
          expect(page).to have_error_message('error')
          expect(page).to have_content 'can\'t be blank'
        end
        
        it "re-renders the page for a new submission" do
          expect(page).to have_field 'Title'
        end
        
        it "doesn't email the managing editors" do
          expect(deliveries).not_to include_email(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Some Clever Title')
          expect(SentEmail.all).not_to include_record(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Some Clever Title')
        end
      end
      
      context "with a large file (>5MB) attached" do
        before do
          fill_in 'Title', with: 'Oversize Submission'
          attach_file('File', File.join(Rails.root, 'spec', 'support', 'Oversize Submission.pdf'))
          click_button 'Submit'
        end
        
        it "doesn't create a new submission" do
          expect(user.reload.submissions).to be_empty
        end
        
        it "displays alert and describes error" do
          expect(page).to have_error_message('error')
          expect(page).to have_content 'can\'t be larger than'
        end
        
        it "re-renders the page for a new submission" do
          expect(page).to have_field 'Title'
        end
        
        it "doesn't email the managing editors" do
          expect(deliveries).not_to include_email(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Some Clever Title')
          expect(SentEmail.all).not_to include_record(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Some Clever Title')
        end
      end
      
      context "with a forbidden file extension" do
        before do
          fill_in 'Title', with: 'Some Clever Title'
          attach_file('File', File.join(Rails.root, 'spec', 'support', 'Bad Sample Submission.sql'))
          click_button 'Submit'
        end
        
        it "doesn't create a new submission" do
          expect(user.reload.submissions).to be_empty
        end
        
        it "displays alert and describes error" do
          expect(page).to have_error_message('error')
          expect(page).to have_content 'not allowed'
        end
        
        it "re-renders the page for a new submission" do
          expect(page).to have_field 'Title'
        end
        
        it "doesn't email the managing editors" do
          expect(deliveries).not_to include_email(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Some Clever Title')
          expect(SentEmail.all).not_to include_record(subject_begins: 'New Submission', to: managing_editor.email, body_includes: 'Some Clever Title')
        end
      end
    end
    
    # index
    describe "listing submissions" do
      context "with one fresh submission" do
        before do
          @fresh_submission = create(:submission, author: user)
          visit author_center_index_path
        end
        
        it "displays only the fresh submission" do
          bordered_tables = all('table.table-bordered')
          expect(bordered_tables.size).to eq(1)
          
          within bordered_tables.first do
            rows = all('tr')
            expect(rows.size).to eq(1)
            
            within rows.first do
              cells = all('td')
              expect(cells.size).to eq(2)
              
              within cells.first do
                expect(page).to have_selector('dd', text: @fresh_submission.title)
                expect(page).to have_selector('dd', text: @fresh_submission.area.name)
                expect(page).to have_selector('dd', text: @fresh_submission.date_submitted_pretty)
                expect(page).to have_link('Withdraw')
              end
              
              within cells.last do
                expect(page).to have_content('Awaiting assignment to an area editor')
              end
            end
            
          end
        end
        
        it "has a working download link to the manuscript file" do
          click_link @fresh_submission.title
          expect(page.response_headers['Content-Type']).to eq 'application/pdf'
        end
      end
      
      context "with one fresh submission and one desk rejected submission" do
        before do
          @fresh_submission = create(:submission, author: user)
          @desk_rejected_submission = create(:desk_rejected_submission, author: user)
          visit author_center_index_path
        end
        
        it "displays only the fresh submission" do
          expect(page).not_to have_content(@desk_rejected_submission.title)
          
          bordered_tables = all('table.table-bordered')
          expect(bordered_tables.size).to eq(1)
          
          within bordered_tables.first do
            rows = all('tr')
            expect(rows.size).to eq(1)
            
            within rows.first do
              cells = all('td')
              expect(cells.size).to eq(2)
              
              within cells.first do
                expect(page).to have_selector('dd', text: @fresh_submission.title)
                expect(page).to have_selector('dd', text: @fresh_submission.area.name)
                expect(page).to have_selector('dd', text: @fresh_submission.date_submitted_pretty)
                expect(page).to have_link('Withdraw')
              end
              
              within cells.last do
                expect(page).to have_content('Awaiting assignment to an area editor')
              end
            end
            
          end
        end
      end
      
      context "with one fresh submission, one under review, and one accepted" do
        before do
          @fresh_submission = create(:submission, author: user)
          @under_review_submission = create(:submission_with_one_completed_referee_assignment_one_open_request, author: user)
          @under_review_submission.referee_assignments.first.update_attributes(report_completed_at: 8.days.ago)
          @accepted_submission = create(:desk_rejected_submission, author: user)
          visit author_center_index_path
        end
        
        it "displays only the fresh and under review submissions" do
          expect(page).not_to have_content(@accepted_submission.title)
          
          bordered_tables = all('table.table-bordered')
          expect(bordered_tables.size).to eq(2)
          
          within bordered_tables.first do
            rows = all('tr')
            expect(rows.size).to eq(1)
            
            within rows.first do
              cells = all('td')
              expect(cells.size).to eq(2)
              
              within cells.first do
                expect(page).to have_selector('dd', text: @fresh_submission.title)
                expect(page).to have_selector('dd', text: @fresh_submission.area.name)
                expect(page).to have_selector('dd', text: @fresh_submission.date_submitted_pretty)
                expect(page).to have_link('Withdraw')
              end
              
              within cells.last do
                expect(page).to have_content('Awaiting assignment to an area editor')
              end
            end
          end
          
          within bordered_tables.last do
            rows = all('tr')
            expect(rows.size).to eq(4)
            
            within rows[0] do
              cells = all('td')
              expect(cells.size).to eq(2)
              
              within cells.first do
                expect(page).to have_selector('dd', text: @under_review_submission.title)
                expect(page).to have_selector('dd', text: @under_review_submission.area.name)
                expect(page).to have_selector('dd', text: @under_review_submission.date_submitted_pretty)
                expect(page).to have_link('Withdraw')
              end
              
              within cells.last do
                expect(page).to have_content('External review')
              end
            end
            
            within rows[1] do
              cells = all('td')
              expect(cells[0]).to have_content('Referee')
              expect(cells[1]).to have_content('Contacted')
              expect(cells[2]).to have_content('Responded')
              expect(cells[3]).to have_content('Agreed?')
              expect(cells[4]).to have_content('Report due')
              expect(cells[5]).to have_content('Completed')
            end
            
            within rows[2] do
              assignment = @under_review_submission.referee_assignments.first

              cells = all('td')
              expect(cells[0]).to have_content(assignment.referee_letter)
              expect(cells[1]).to have_content(assignment.date_assigned_pretty)
              expect(cells[2]).to have_content(assignment.date_agreed_pretty)
              expect(cells[3]).to have_content('Y')
              expect(cells[4]).to have_content(assignment.date_due_pretty)
              expect(cells[5]).to have_link(assignment.date_completed_pretty)
            end
            
            within rows[3] do
              assignment = @under_review_submission.referee_assignments.last

              cells = all('td')
              expect(cells[0]).to have_content(assignment.referee_letter)
              expect(cells[1]).to have_content(assignment.date_assigned_pretty)
              expect(cells[2]).to have_content("\u2014")
              expect(cells[3]).to have_content("\u2014")
              expect(cells[4]).to have_content("\u2014")
              expect(cells[5]).to have_content("\u2014")
            end
          end 
        end
        
        it "has a working link to the completed report, suitably anonymized" do
          completed_assignment = @under_review_submission.referee_assignments.first
          click_link completed_assignment.date_completed_pretty
          
          expect(page).to have_link(@under_review_submission.title)
          expect(page).to have_content("Referee #{completed_assignment.referee_letter}")
          expect(page).not_to have_content('To the editors')
          expect(page).not_to have_content(completed_assignment.comments_for_editor)
          expect(page).to have_content('To the author')
          expect(page).to have_content(completed_assignment.comments_for_author)
          expect(page).to have_content('Recommendation')
          expect(page).to have_content(completed_assignment.recommendation)
        end
        
        context "when the report was only recently completed" do
          before do
            @under_review_submission.referee_assignments.first.update_attributes(report_completed_at: 6.days.ago)
          end
          
          it "doesn't link to the completed report" do
            completed_assignment = @under_review_submission.referee_assignments.first
            expect(page).not_to have_link(completed_assignment.date_completed_pretty)
          end
          
          it "redirects to security_breach_path when trying to go to the report directly" do
            visit author_center_referee_assignment_path(@under_review_submission, @under_review_submission.referee_assignments.first)
            expect(current_path).to eq(security_breach_path)
          end
        end
      end

      context "with one submission that needs revisions" do
        before do
          @submission = create(:major_revisions_requested_submission, author: user)
          visit author_center_index_path
        end

        it "displays the editor's comments in a popover", js: true do
          expect(page).not_to have_content 'Editor\'s comments'
          expect(page).not_to have_content 'Lorem ipsum dolor sit amet'
          click_link 'Major Revisions'
          expect(page).to have_content 'Editor\'s comments'
          expect(page).to have_content 'Lorem ipsum dolor sit amet'
        end

        it "has a working link to submit a revision" do
          click_link 'Submit revision'
          expect(page).to have_content 'Submit a revision'
          expect(current_path).to eq new_author_center_revision_path(@submission.id)
        end
      end
    end
    
    # archives
    describe "listing archived submissions" do
      context "with one fresh submission" do
        before do
          @fresh_submission = create(:submission, author: user)
          visit archives_author_center_index_path
        end
        
        it "says there are no archived submissions" do
          expect(page).to have_content('No past submissions')
        end
      end

      context "with one fresh submission and one desk rejected submission" do
        before do
          @fresh_submission = create(:submission, author: user)
          @desk_rejected_submission = create(:desk_rejected_submission, author: user)
          visit archives_author_center_index_path
        end
        
        it "displays only the desk rejected submission" do
          expect(page).not_to have_content(@fresh_submission.title)

          bordered_tables = all('table.table-bordered')
          expect(bordered_tables.size).to eq(1)
          
          within bordered_tables.first do
            rows = all('tr')
            expect(rows.size).to eq(1)
            
            within rows.first do
              cells = all('td')
              expect(cells.size).to eq(2)
              
              within cells.first do
                expect(page).to have_selector('dd', text: @desk_rejected_submission.title)
                expect(page).to have_selector('dd', text: @desk_rejected_submission.area.name)
                expect(page).to have_selector('dd', text: @desk_rejected_submission.date_submitted_pretty)
              end
              
              within cells.last do
                expect(page).to have_content(Decision::REJECT)
              end
            end
          end
        end
        
        it "has a working download link to the desk rejected manuscript file" do
          click_link @desk_rejected_submission.title
          expect(page.response_headers['Content-Type']).to eq 'application/pdf'
        end
        
        it "displays the editor's comments on the desk rejected submission in a popover", js: true do
          expect(page).not_to have_content 'Editor\'s comments'
          click_link 'Reject'
          expect(page).to have_content 'Editor\'s comments'
        end
      end

      context "with one fresh submission, one accepted, and one needing revision" do
        before do
          @fresh_submission = create(:submission, author: user)
          @accepted_submission = create(:accepted_submission, author: user)
          @accepted_submission.referee_assignments.first.update_attributes(report_completed_at: 3.days.ago)
          @accepted_submission.referee_assignments.last.update_attributes(report_completed_at: 3.days.ago)
          @major_revisions_requested_submission = create(:major_revisions_requested_submission, author: user)
          visit archives_author_center_index_path
        end
        
        it "does not display the fresh submission or the one needing revision" do
          expect(page).not_to have_content(@fresh_submission.title)
          expect(page).not_to have_content(@major_revisions_requested_submission.title)
        end
        
        it "does display the accepted submission" do  
          bordered_tables = all('table.table-bordered')
          expect(bordered_tables.size).to eq(1)
          
          within bordered_tables.first do
            rows = all('tr')
            expect(rows.size).to eq(4)
            
            within rows[0] do
              cells = all('td')
              expect(cells.size).to eq(2)
              
              within cells.first do
                expect(page).to have_selector('dd', text: @accepted_submission.title)
                expect(page).to have_selector('dd', text: @accepted_submission.area.name)
                expect(page).to have_selector('dd', text: @accepted_submission.date_submitted_pretty)
              end
              
              within cells.last do
                expect(page).to have_content(Decision::ACCEPT)
              end
            end
            
            within rows[1] do
              cells = all('td')
              expect(cells[0]).to have_content('Referee')
              expect(cells[1]).to have_content('Contacted')
              expect(cells[2]).to have_content('Responded')
              expect(cells[3]).to have_content('Agreed?')
              expect(cells[4]).to have_content('Report due')
              expect(cells[5]).to have_content('Completed')
            end
            
            within rows[2] do
              assignment = @accepted_submission.referee_assignments.first

              cells = all('td')
              expect(cells[0]).to have_content(assignment.referee_letter)
              expect(cells[1]).to have_content(assignment.date_assigned_pretty)
              expect(cells[2]).to have_content(assignment.date_agreed_pretty)
              expect(cells[3]).to have_content('Y')
              expect(cells[4]).to have_content(assignment.date_due_pretty)
              expect(cells[5]).to have_link(assignment.date_completed_pretty)
            end
            
            within rows[3] do
              assignment = @accepted_submission.referee_assignments.last

              cells = all('td')
              expect(cells[0]).to have_content(assignment.referee_letter)
              expect(cells[1]).to have_content(assignment.date_assigned_pretty)
              expect(cells[2]).to have_content(assignment.date_agreed_pretty)
              expect(cells[3]).to have_content('Y')
              expect(cells[4]).to have_content(assignment.date_due_pretty)
              expect(cells[5]).to have_link(assignment.date_completed_pretty)
            end
          end
        end

        it "has a working link to the first report on the accepted submission" do
          assignment = @accepted_submission.referee_assignments.first
          links = all(:link, text: assignment.date_completed_pretty)

          links[0].click
          expect(page).to have_link(@accepted_submission.title)
          expect(page).to have_content("Referee #{assignment.referee_letter}")
          expect(page).not_to have_content('To the editors')
          expect(page).not_to have_content(assignment.comments_for_editor)
          expect(page).to have_content('To the author')
          expect(page).to have_content(assignment.comments_for_author)
          expect(page).to have_content('Recommendation')
          expect(page).to have_content(assignment.recommendation)
        end
        
        it "has a working link to the second report on the accepted submission" do
          assignment = @accepted_submission.referee_assignments.last
          links = all(:link, text: assignment.date_completed_pretty)
          
          links[1].click
          expect(page).to have_link(@accepted_submission.title)
          expect(page).to have_content("Referee #{assignment.referee_letter}")
          expect(page).not_to have_content('To the editors')
          expect(page).not_to have_content(assignment.comments_for_editor)
          expect(page).to have_content('To the author')
          expect(page).to have_content(assignment.comments_for_author)
          expect(page).to have_content('Recommendation')
          expect(page).to have_content(assignment.recommendation)
        end
        
        it "displays the editor's comments on the accepted submission in a popover", js: true do
          expect(page).not_to have_content 'Editor\'s comments'
          expect(page).not_to have_content 'Lorem ipsum dolor sit amet'
          click_link 'Accept'
          expect(page).to have_content 'Editor\'s comments'
          expect(page).to have_content 'Lorem ipsum dolor sit amet'
        end
      end
    end
    
    # withdraw
    describe "withdrawing a submission" do
      context "when the submission is fresh" do
        before do
          @fresh_submission = create(:submission, author: user)
          visit author_center_index_path
          find_withdraw_link(@fresh_submission).click         
        end
        
        it "withdraws and archives the submission" do
          @fresh_submission.reload
          expect(@fresh_submission).to be_withdrawn
          expect(@fresh_submission).to be_archived
        end
        
        it "emails the editors and authors but no referees" do
          expect(deliveries).to include_email(subject_begins: 'Submission Withdrawn', to: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Submission Withdrawn', to: managing_editor.email)
          
          expect(deliveries).to include_email(subject_begins: 'Confirmation: Submission Withdrawn', to: user.email, cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Confirmation: Submission Withdrawn', to: user.email, cc: managing_editor.email)
                                                    
          expect(deliveries).not_to include_email(subject_begins: 'Withdrawn Submission')
          expect(SentEmail.all).not_to include_record(subject_begins: 'Withdrawn Submission')
        end
        
        it "flashes success and takes the user back to their list of submissions" do
          expect(page.current_path).to eq(author_center_index_path)
          expect(page).to have_success_message('withdrawn')
        end
        
        it "no longer lists the submission" do
          expect(page).to have_content('No active submissions')
        end
      end
      
      context "when the submission has been sent out for review" do
        before do
          @submission_under_review = create(:submission_with_one_completed_referee_assignment, author: user)
          create(:agreed_referee_assignment, submission: @submission_under_review)
          visit author_center_index_path
          find_withdraw_link(@submission_under_review).click
        end
        
        it "withdraws and archives the submission" do
          @submission_under_review.reload
          expect(@submission_under_review).to be_withdrawn
          expect(@submission_under_review).to be_archived
        end
        
        it "emails the editors, authors, and referees" do
          area_editor = @submission_under_review.area_editor
          
          expect(deliveries).to include_email(subject_begins: 'Submission Withdrawn', to: area_editor.email, cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Submission Withdrawn', to: area_editor.email, cc: managing_editor.email)
          
          expect(deliveries).to include_email(subject_begins: 'Confirmation: Submission Withdrawn', to: user.email, cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Confirmation: Submission Withdrawn', to: user.email, cc: managing_editor.email)

          @submission_under_review.pending_referee_assignments.each do |assignment|
            email = find_email(subject_begins: 'Withdrawn Submission', to: assignment.referee.email, cc: area_editor.email)
            expect(email.body).to match(/A submission you were asked to review/)
            expect(email.body).not_to match(/The author .* has decided to withdraw/)
            expect(SentEmail.all).to include_record(subject_begins: 'Withdrawn Submission', to: assignment.referee.email, cc: area_editor.email)
          end

          @submission_under_review.referee_assignments.where(report_completed: true).each do |assignment|
            email = find_email(subject_begins: 'Withdrawn Submission', to: assignment.referee.email, cc: area_editor.email)
            expect(email.body).to match(/The author .* has decided to withdraw/)
            expect(email.body).not_to match(/A submission you were asked to review/)
            expect(SentEmail.all).to include_record(subject_begins: 'Withdrawn Submission', to: assignment.referee.email, cc: area_editor.email)
          end
        end
        
        it "flashes success and takes the user back to their list of submissions" do
          expect(page.current_path).to eq(author_center_index_path)
          expect(page).to have_success_message('withdrawn')
        end
        
        it "no longer lists the submission" do
          expect(page).to have_content 'No active submissions'
        end
      end
    end
  end
  
  shared_examples_for "no actions are accessible" do |redirect_path|
    # new
    describe "new submission page" do
      before { visit new_author_center_path }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # create
    describe "create submission" do
      before do
        @params = { title: 'Some Clever Title', area_id: '1' }        
      end
      
      it "doesn't create a new submission" do
        expect { 
          post author_center_index_path, submission: @params 
        }.not_to change { Submission.count }
      end
      
      it "redirects to #{redirect_path}" do
        post author_center_index_path, submission: @params
        expect(response).to redirect_to(send(redirect_path))
      end
      
    end
    
    # index
    describe "index submissions" do
      before { visit author_center_index_path }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # archives
    describe "archive submissions" do
      before { visit archives_author_center_index_path }
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
    
    # withdraw
    describe "withdraw submission" do
      before do
        @submission = create(:submission)
        visit withdraw_author_center_path(@submission)
      end
      
      it "doesn't withdraw the submission" do
        expect(@submission.withdrawn?).to eq(false)
      end
      
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
  end
  
  context "when logged in as an editor" do
    before { valid_sign_in(managing_editor) }
    
    it_behaves_like "no actions are accessible", :security_breach_path
  end
  
  context "when not logged in" do
    it_behaves_like "no actions are accessible", :signin_path
  end
  
end
