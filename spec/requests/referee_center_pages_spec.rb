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
        @agreed_assignment = create(:agreed_referee_assignment, referee: referee)
        visit referee_center_index_path
      end

      it "lists active assignments" do
        expect(page).to have_content(submission.id.to_s )
        expect(page).to have_link(submission.title,
                                  href: edit_response_referee_center_path(assignment))
        expect(page).to have_link(@agreed_assignment.submission.title,
                                  href: edit_report_referee_center_path(@agreed_assignment))
        expect(page).to have_link('Download', href: submission.manuscript_file)
      end
    end

    # edit_response
    describe "respond to request page" do
      context "when no response has been recorded yet" do
        before do
          assignment
          visit referee_center_index_path
          click_link submission.title
        end

        it "offers the option to agree or decline" do
          expect(page).to have_field('referee_assignment_agreed_true')
          expect(page).to have_field('referee_assignment_agreed_false')
          expect(page).to have_field('referee_assignment_decline_comment')
          expect(page).to have_button('Submit')
        end

        context "when the submission is a revision" do
          before do
            submission = create(:first_revision_submission)
            assignment.update_attributes(submission: submission)

            @previous_submission = submission.previous_revision
            @previous_assignment = @previous_submission.referee_assignments.first
            @previous_assignment.update_attributes(referee: referee)

            assignment.agree!
            visit edit_report_referee_center_path(assignment)
          end

          it "links to the previous version and report" do
            expect(page).to have_link "Previous version", href: @previous_submission.manuscript_file
            expect(page).to have_link "Previous report", href: referee_center_path(@previous_assignment)
          end

          it "disables the major/minor revisions options" do
            major_option = field_labeled('Recommendation').find(:xpath, ".//option[text() = '#{Decision::MAJOR_REVISIONS}']")
            minor_option = field_labeled('Recommendation').find(:xpath, ".//option[text() = '#{Decision::MINOR_REVISIONS}']")
            expect(major_option.disabled?).to be_true
            expect(minor_option.disabled?).to be_true
          end
        end
      end

      context "when already agreed" do
        before do
          assignment.agree!
          visit edit_response_referee_center_path(assignment)
        end

        it "flashes an error and redirects to the edit_report page" do
          expect(page).to have_error_message 'This request has already been accepted.'
          expect(current_path).to eq edit_report_referee_center_path(assignment)
        end
      end

      context "when already declined" do
        before do
          assignment.decline
          visit edit_response_referee_center_path(assignment)
        end

        it "flashes an error and redirects to the referee center" do
          expect(page).to have_error_message 'That request has already been declined.'
          expect(current_path).to eq referee_center_index_path
        end
      end
    end

    # update_response
    describe "update response" do
      context "when no response is recorded yet" do

        describe "agree to the assignment" do
          before do
            visit edit_response_referee_center_path(assignment)
            choose('referee_assignment_agreed_true')
            click_button('Submit')
          end

          it "sets agreed to true" do
            assignment.reload
            expect(assignment.agreed).to be_true
          end

          it "flashes a thank you and redirects to the edit report page" do
            expect(current_path).to eq(edit_report_referee_center_path(assignment))
            expect(page).to have_success_message 'Thanks for agreeing'
          end

          it "sends a confirmation to the author (cc area editor)" do
            expect(deliveries).to include_email(subject_begins: 'Assignment Confirmation',
                                                to: referee.email,
                                                cc: assignment.submission.area_editor.email)
            expect(SentEmail.all).to include_record(subject_begins: 'Assignment Confirmation',
                                                    to: referee.email,
                                                    cc: assignment.submission.area_editor.email)
          end
        end

        describe "decline the assignment" do
          before do
            visit edit_response_referee_center_path(assignment)
            choose('referee_assignment_agreed_false')
            click_button('Submit')
          end

          it "sets agreed to false" do
            assignment.reload
            expect(assignment.agreed).to eq(false)
          end

          it "redirects to the edit page and flashes a thank you" do
            expect(current_path).to eq(referee_center_index_path)
            expect(page).to have_success_message 'Thanks for letting us know!'
          end

          it "notifies the editor" do
            expect(deliveries).to include_email(subject_begins: 'Referee Assignment Declined', to: area_editor.email, cc: managing_editor.email)
            expect(SentEmail.all).to include_record(subject_begins: 'Referee Assignment Declined', to: area_editor.email, cc: managing_editor.email)
          end
        end

      end

      context "when already agreed" do
        before do
          assignment.agree!
          put update_response_referee_center_path(assignment), referee_assignment: { agreed: false }
        end

        it "leaves agreed true, flashes an error, and redirects to the report page" do
          assignment.reload
          expect(assignment.agreed).to be_true
          expect(response).to redirect_to edit_report_referee_center_path(assignment)
          follow_redirect!
          expect(response.body).to include 'This request has already been accepted.'
        end
      end

      context "when already declined" do
        before do
          assignment.decline
          put update_response_referee_center_path(assignment), referee_assignment: { agreed: true }
        end

        it "leaves agreed false, flashes an error, and redirects to the report page" do
          assignment.reload
          expect(assignment.agreed).to eq false
          expect(response).to redirect_to referee_center_index_path
          follow_redirect!
          expect(response.body).to include 'That request has already been declined.'
        end
      end
    end

    # edit_report
    describe "view edit report page" do
      context "when agreed is true" do
        before do
          assignment.agree!
          visit edit_report_referee_center_path(assignment)
        end

        it "offers a form for entering the report" do
          expect(page).to have_field('To the author')
          expect(page).to have_field('referee_assignment_attachment_for_author')
          expect(page).to have_field('To the editors')
          expect(page).to have_field('referee_assignment_attachment_for_editor')
          expect(page).to have_field('Recommendation')
          expect(page).to have_button('Submit')
        end
      end

      context "when agreed is nil" do
        before do
          visit edit_report_referee_center_path(assignment)
        end

        it "flashes a warning and redirects to the edit_response page" do
          expect(page).to have_content 'Please first indicate whether you accept this request.'
          expect(current_path).to eq edit_response_referee_center_path(assignment)
        end
      end

      context "when agreed is false" do
        before do
          assignment.decline
          visit edit_report_referee_center_path(assignment)
        end

        it "flashes a warning and redirects to the edit_response page" do
          expect(page).to have_error_message 'That request was declined.'
          expect(current_path).to eq referee_center_index_path
        end
      end
    end

    # update_report
    describe "submit the report" do
      context "when the report hasn't been completed yet" do
        before do
          @other_assignment = create(:referee_assignment, referee: referee, submission: submission)
          @other_assignment.agree!
          @second_other_assignment = create(:referee_assignment, referee: referee, submission: submission)
          @second_other_assignment.agree!
          assignment.agree!
          visit edit_report_referee_center_path(assignment)
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
            visit edit_report_referee_center_path(@other_assignment)
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
            visit edit_report_referee_center_path(@other_assignment)
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
            visit edit_report_referee_center_path(@other_assignment)
            fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
            attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
            fill_in 'To the author', with: 'consectetur adipisicing elit'
            attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
            select Decision::MAJOR_REVISIONS, from: 'Recommendation'
            click_button 'Submit'

            visit edit_report_referee_center_path(@second_other_assignment)
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

      context "when the report has already been completed" do
        before do
          assignment.agree!
          visit edit_report_referee_center_path(assignment)
          fill_in 'To the editor', with: 'Lorem ipsum dolor sit amet'
          fill_in 'To the author', with: 'consectetur adipisicing elit'
          select Decision::MAJOR_REVISIONS, from: 'Recommendation'
          click_button 'Submit'
          put update_report_referee_center_path(assignment), referee_assignment: { comments_for_editor: 'Foo bar', recommendation: Decision::REJECT }
        end

        it "doesn't change the report; redirects instead and flashes an error" do
          assignment.reload
          expect(assignment.comments_for_editor).not_to eq 'Foo bar'
          expect(response).to redirect_to(referee_center_path(assignment))
          follow_redirect!
          expect(response.body).to include 'This report has already been completed.'
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

    # edit_response
    describe "edit response page" do
      before { get edit_response_referee_center_path(assignment) }
      it { should bounce_to(send(redirect_path)) }
    end

    # update_response
    describe "update response" do
      before do
        put update_response_referee_center_path(assignment),
            { referee_assignment: { agreed: true } }
      end

      it "leaves agreed nil" do
        assignment.reload
        expect(assignment.agreed).to be_nil
      end

      it { should bounce_to(send(redirect_path)) }
    end

    # edit_report
    describe "edit report page" do
      before { get edit_report_referee_center_path(assignment) }
      it { should bounce_to(send(redirect_path)) }
    end

    # update_report
    describe "update report" do
      before do
        put update_report_referee_center_path(assignment),
            { referee_assignment: { recommendation: Decision::REJECT } }
      end

      it "leaves the report unchanged" do
        assignment.reload
        expect(assignment.recommendation).to be_nil
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
