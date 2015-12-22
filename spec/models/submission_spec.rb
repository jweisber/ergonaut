# == Schema Information
#
# Table name: submissions
#
#  id                                        :integer          not null, primary key
#  title                                     :string(255)
#  user_id                                   :integer
#  created_at                                :datetime         not null
#  updated_at                                :datetime         not null
#  decision_approved                         :boolean
#  decision                                  :string(255)
#  archived                                  :boolean
#  withdrawn                                 :boolean
#  manuscript_file                           :string(255)
#  area_editor_comments_for_managing_editors :text
#  area_editor_comments_for_author           :text
#  area_id                                   :integer
#  original_id                               :integer
#  revision_number                           :integer
#  auth_token                                :string(255)
#  decision_entered_at                       :datetime
#

require 'spec_helper'

describe Submission do
  let!(:managing_editor) { create(:managing_editor) }
  let(:submission) { build(:submission) }
  subject { submission }  
  
  
  # attributes
  
  it { should respond_to(:title) }
  it { should respond_to(:author) }
  it { should respond_to(:area_editor) }
  it { should respond_to(:referee_assignments) }
  it { should respond_to(:referees) }
  it { should respond_to(:decision_approved) }
  it { should respond_to(:decision) }
  it { should respond_to(:archived) }
  it { should respond_to(:manuscript_file) }
  it { should respond_to(:area_editor_comments_for_managing_editors) }
  it { should respond_to(:area_editor_comments_for_author) }
  it { should respond_to(:original) }
  it { should respond_to(:revision_number) }
  it { should respond_to(:revisions) }
  it { should respond_to(:auth_token) }
  it { should respond_to(:decision_entered_at) }
  it { should be_valid }
  
  
  # defaults
  
  its(:revision_number) { should eq(0) }
  its(:decision_approved) { should eq(false) }
  its(:decision) { should eq(Decision::NO_DECISION) }
  its(:archived) { should eq(false) }
  its(:withdrawn) { should eq(false) }
  
  it "sets archived to true when decision_approved is true" do
    submission.update_attributes(decision: Decision::REJECT, decision_approved: true)
    expect(submission.reload.archived).to eq(true)
  end
  
  
  # validations
  
  it "is not valid without a title" do
    submission.title = ""
    expect(submission).not_to be_valid
  end
  
  it "is not valid without an author" do
    submission.author = nil
    expect(submission).not_to be_valid
  end
  
  it "is not valid without an area" do
    submission.area = nil
    expect(submission).not_to be_valid
  end
  
  it "is not valid without a revision_number" do
    submission.revision_number = nil
    expect(submission).not_to be_valid
  end
  
  it "is not valid when revision_number is not a number" do
    submission.revision_number = 'hello'
    expect(submission).not_to be_valid
  end
  
  it "is not valid unless decision is one of in Decision.all" do
    submission.decision = 'foo'
    expect(submission).not_to be_valid
  end
  
  it "is not valid when manuscript_file is larger than 5MB" do
    submission.manuscript_file = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Oversize Submission.pdf'))
    expect(submission).not_to be_valid
  end
  
  
  # instance methods
  
  describe "#withdraw" do
    
    let(:submission) { create(:submission) }
    before do
      submission.withdraw
    end
    
    it "sets withdrawn to true" do
      expect(submission.withdrawn).to be_true
    end
    
    it "sets archived to true" do
      expect(submission.archived).to be_true
    end
    
    it "saves the submission" do
      expect(submission.changed?).to eq(false)
    end
    
    it "emails a notification to the editors, and a confirmation to the author" do
      expect(deliveries).to include_email(to: managing_editor.email, subject_begins: 'Submission Withdrawn')
      expect(SentEmail.all).to include_record(to: managing_editor.email, subject_begins: 'Submission Withdrawn')
      
      expect(deliveries).to include_email(to: submission.author.email, subject: 'Confirmation: Submission Withdrawn')
      expect(SentEmail.all).to include_record(to: submission.author.email, subject: 'Confirmation: Submission Withdrawn')      
    end
    
    context "when there is an unanswered referee request" do
      let(:submission_sent_out_for_review) { create(:submission_sent_out_for_review) }
      before { submission_sent_out_for_review.withdraw }
      
      it "emails the referee" do
        referee = submission_sent_out_for_review.referee_assignments.first.referee
        expect(deliveries).to include_email(to: referee.email, subject: 'Withdrawn Submission')
        expect(SentEmail.all).to include_record(to: referee.email, subject: 'Withdrawn Submission')
      end
    end
    
    context "when there is an incomplete referee report" do
      let(:submission_with_two_agreed_referee_assignments) { create(:submission_with_two_agreed_referee_assignments) }
      before { submission_with_two_agreed_referee_assignments.withdraw }
      
      it "emails the referee whose report is incomplete" do
        referee = submission_with_two_agreed_referee_assignments.pending_referee_assignments.first.referee
        expect(deliveries).to include_email(to: referee.email, subject: 'Withdrawn Submission')
        expect(SentEmail.all).to include_record(to: referee.email, subject: 'Withdrawn Submission')
      end
    end
  end
  
  describe "#unarchive" do
    
    let(:accepted_submission) { create(:accepted_submission) }
    before { accepted_submission.unarchive(managing_editor) }
    
    it "sets archived to false" do
      expect(accepted_submission.archived).to eq(false)
    end
    
    it "sets withdrawn to false" do
      expect(accepted_submission.withdrawn).to eq(false)
    end
    
    it "saves the submission" do
      expect(accepted_submission.changed?).to eq(false)
    end
    
    it "sends a notification email to the managing and area editors" do
      expect(deliveries).to include_email(to: managing_editor.email, subject_begins: 'Unarchived: ')
      expect(SentEmail.all).to include_record(to: managing_editor.email, subject_begins: 'Unarchived: ')
    end
    
  end
  
  describe "#pending_referee_assignments" do
    let(:submission_assigned_to_area_editor) { create(:submission_assigned_to_area_editor) }
    let(:submission_sent_out_for_review) { create(:submission_sent_out_for_review) }
    let(:submission_with_two_agreed_referee_assignments) { create(:submission_with_two_agreed_referee_assignments) }
    let(:submission_with_two_completed_referee_assignments) { create(:submission_with_two_completed_referee_assignments) }
    
    it "returns all non-declined, non-canceled, non-completed referee assignments" do
      expect(submission_assigned_to_area_editor.pending_referee_assignments.size).to eq(0)
      expect(submission_sent_out_for_review.pending_referee_assignments.size).to eq(1)
      expect(submission_with_two_agreed_referee_assignments.pending_referee_assignments.size).to eq(1)
      expect(submission_with_two_completed_referee_assignments.pending_referee_assignments.size).to eq(0)
    end
  end
  
  describe "#non_canceled_referee_assignments" do
    let(:submission_assigned_to_area_editor) { create(:submission_assigned_to_area_editor) }
    let(:submission_sent_out_for_review) { create(:submission_sent_out_for_review) }
    let(:submission_with_two_agreed_referee_assignments) { create(:submission_with_two_agreed_referee_assignments) }
    let(:submission_with_two_completed_referee_assignments) { create(:submission_with_two_completed_referee_assignments) }
    
    it "returns all non-declined, non-canceled, non-completed referee assignments" do
      expect(submission_assigned_to_area_editor.non_canceled_referee_assignments.size).to eq(0)
      expect(submission_sent_out_for_review.non_canceled_referee_assignments.size).to eq(1)
      expect(submission_with_two_agreed_referee_assignments.non_canceled_referee_assignments.size).to eq(3)
      expect(submission_with_two_completed_referee_assignments.non_canceled_referee_assignments.size).to eq(2)
    end
  end
  
  describe "#non_canceled_non_declined_referee_assignments" do
    let(:submission_assigned_to_area_editor) { create(:submission_assigned_to_area_editor) }
    let(:submission_sent_out_for_review) { create(:submission_sent_out_for_review) }
    let(:submission_with_two_agreed_referee_assignments) { create(:submission_with_two_agreed_referee_assignments) }
    let(:submission_with_two_completed_referee_assignments) { create(:submission_with_two_completed_referee_assignments) }
    
    it "returns all non-canceled, non-declined referee assignments" do
      expect(submission_assigned_to_area_editor.non_canceled_non_declined_referee_assignments.size).to eq(0)
      expect(submission_sent_out_for_review.non_canceled_non_declined_referee_assignments.size).to eq(1)
      expect(submission_with_two_agreed_referee_assignments.non_canceled_non_declined_referee_assignments.size).to eq(2)
      expect(submission_with_two_completed_referee_assignments.non_canceled_non_declined_referee_assignments.size).to eq(2)
    end
  end

  describe "#date_submitted_pretty" do
    let (:submission) { create(:submission) }
    
    it "returns the created_at date formatted like Jan. 17, 2014" do
      submission.update_attributes(created_at: Date.new(2014, 1, 17)) 
      expect(submission.date_submitted_pretty).to eq("Jan. 17, 2014")
    end
  end 

  describe "#latest_version_number" do
    
    context "when submission is original" do
      let(:submission) { create(:submission) }
          
      it "returns the highest revision_number for all submissions that are revisions of this one" do
        expect(submission.latest_version_number).to eq(0)
      end   
    end
    
    context "when submission is first revision" do
      let(:first_revision_submission) { create(:first_revision_submission) }
      
      it "returns the highest revision_number for all submissions that are revisions of this one" do
        expect(first_revision_submission.latest_version_number).to eq(1)
      end
    end
    
    context "when submission is first revision" do
      let(:second_revision_submission) { create(:second_revision_submission) }
      
      it "returns the highest revision_number for all submissions that are revisions of this one" do
        expect(second_revision_submission.latest_version_number).to eq(2)
      end
    end

  end
  
  describe "#is_latest_version?" do
    
    context "when this submission is the original" do
      let(:submission) { create(:submission) }
        
      it "returns true" do
        expect(submission.is_latest_version?).to be_true
      end
    end
    
    context "when this submission is the first and only revision" do
      let(:first_revision_submission) { create(:first_revision_submission) }
      
      it "returns true for the revision" do
        expect(first_revision_submission.is_latest_version?).to be_true
      end
      
      it "returns false for the original" do
        expect(first_revision_submission.original.is_latest_version?).to eq(false)
      end
    end
    
    context "when this submission is the second and final revision" do
      let(:second_revision_submission) { create(:second_revision_submission) }
      
      it "returns true for the submission" do
        expect(second_revision_submission.is_latest_version?).to be_true
      end
      
      it "returns false for both predecessors" do
        expect(second_revision_submission.original.is_latest_version?).to eq(false)
        expect(second_revision_submission.original.revisions[1].is_latest_version?).to eq(false)
      end
    end
  end
  
  describe "#previous_versions" do
    
    context "when this submission is the original" do
      let(:submission) { create(:submission) }
        
      it "returns empty" do
        expect(submission.previous_versions).to be_empty
      end
    end
    
    context "when this submission is the first revision" do
      let(:first_revision_submission) { create(:first_revision_submission) }
      
      it "contains just the original submission" do
        expect(first_revision_submission.previous_versions.size).to eq(1)
        expect(first_revision_submission.previous_versions).to include(first_revision_submission.original)
      end
    end
    
    context "when this submission is the second revision" do
      let(:second_revision_submission) { create(:second_revision_submission) }
      
      it "returns the first revision" do
        original = second_revision_submission.original
        previous = Submission.where(original_id: original.id, revision_number: 1).first
        expect(second_revision_submission.previous_versions.size).to eq(2)
        expect(second_revision_submission.previous_versions).to include(original)
        expect(second_revision_submission.previous_versions).to include(previous)
      end
    end
  end

  describe "#previous_revision" do
    
    context "when this submission is the original" do
      let(:submission) { create(:submission) }
        
      it "returns nil" do
        expect(submission.previous_revision).to be_nil
      end
    end
    
    context "when this submission is the first revision" do
      let(:first_revision_submission) { create(:first_revision_submission) }
      
      it "returns the original submission" do
        expect(first_revision_submission.previous_revision).to eq(first_revision_submission.original)
      end
    end
    
    context "when this submission is the second revision" do
      let(:second_revision_submission) { create(:second_revision_submission) }
      
      it "returns the first revision" do
        original = second_revision_submission.original
        previous = Submission.where(original_id: original.id, revision_number: 1).first
        expect(second_revision_submission.previous_revision).to eq(previous)
      end
    end
  end
  
  describe "#previous_assignment(referee)" do
    
    context "when there is no previous version" do
      before do
        @submission = create(:submission)
        @referee = create(:referee)
      end
      
      it "returns nil" do
        previous_assignment = @submission.previous_assignment(@referee)
        expect(previous_assignment).to be_nil
      end
    end
    
    context "when the referee didn't review the previous version" do
      before do
        @submission = create(:first_revision_submission)
        @referee = create(:referee)
      end
    
      it "returns nil" do
        previous_assignment = @submission.previous_assignment(@referee)
        expect(previous_assignment).to be_nil
      end
    end
    
    context "when the referee did review the previous version" do
      before do
        @submission = create(:first_revision_submission)
        previous_submission = @submission.previous_revision
        previous_reports = previous_submission.referee_assignments.where(report_completed: true)
        @referee = previous_reports.sample.referee
      end
    
      it "returns the assignment for that referee from the previous version" do
        previous_assignment = @submission.previous_assignment(@referee)
        expect(previous_assignment).not_to be_nil
      end
    end
  end
  
  describe "#needs_revision?" do
    
    context "when this submission is the latest version, and a decision of #{Decision::MAJOR_REVISIONS}/#{Decision::MINOR_REVISIONS} has been approved" do
      let(:major_revisions_requested_submission) { create(:major_revisions_requested_submission) }
      let(:minor_revisions_requested_submission) { create(:minor_revisions_requested_submission) }

      it "returns true" do
        expect(major_revisions_requested_submission.needs_revision?).to be_true
        expect(minor_revisions_requested_submission.needs_revision?).to be_true
      end
    end
    
    context "when this submission is not the latest version" do
      let(:second_revision_submission_minor_revisions_requested) { create(:second_revision_submission_minor_revisions_requested) }

      it "returns false" do
        expect(second_revision_submission_minor_revisions_requested.original.needs_revision?).to eq(false)
        expect(second_revision_submission_minor_revisions_requested.original.revisions[1].needs_revision?).to eq(false)
      end
    end
    
    context "when this submission does not have an approved decision" do
      let(:submission_assigned_to_area_editor) { create(:submission_assigned_to_area_editor) }
      
      it "returns false" do
        submission_assigned_to_area_editor.decision = Decision::MAJOR_REVISIONS
        expect(submission_assigned_to_area_editor.needs_revision?).to eq(false)
      end
    end
    
    context "when this submission has a decision of #{Decision::REJECT}/#{Decision::ACCEPT}" do
      let(:accepted_submission) { create(:accepted_submission) }
      let(:rejected_after_review_submission) { create(:rejected_after_review_submission) }
      
      it "returns false" do
        expect(accepted_submission.needs_revision?).to eq(false)
        expect(rejected_after_review_submission.needs_revision?).to eq(false)
      end
    end
  end
  
  describe "#submit_revision" do
    let(:major_revisions_requested_submission) { create(:major_revisions_requested_submission) }
    let(:revised_submission) { Submission.last}
    let(:params) { ActionController::Parameters.new({ title: 'Revised Version', 
                                                      manuscript_file: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf')), 
                                                      decision: Decision::ACCEPT,
                                                      decision_approved: true }) }

    before(:each) do
      major_revisions_requested_submission.submit_revision(params)
      revised_submission = Submission.last
    end
        
    it "archives this submission" do
      expect(major_revisions_requested_submission.archived).to be_true
    end
    
    it "saves this submission" do
      expect(major_revisions_requested_submission.persisted?).to be_true
    end

    it "creates a new submission" do
      expect(revised_submission).not_to eq(major_revisions_requested_submission)
    end
    
    it "creates a submission whose original is this submission" do
      expect(revised_submission.original).to eq(major_revisions_requested_submission)
    end
    
    it "creates a submission with the same title, or the title included in the params" do
      expect([major_revisions_requested_submission.title, params[:title]]).to include(revised_submission.title)
    end
    
    it "creates a submission with the same author" do
      expect(revised_submission.author).to eq(major_revisions_requested_submission.author)
    end

    it "creates a submission with the same area" do
      expect(revised_submission.area).to eq(major_revisions_requested_submission.area)
    end
    
    it "creates a submission with #{Decision::NO_DECISION}" do
      expect(revised_submission.decision).to eq(Decision::NO_DECISION)
    end
    
    it "creates a submission whose decision is not approved" do
      expect(revised_submission.decision_approved).to eq(false)
    end
    
    it "creates a submission whose revision number is incremented by 1" do
      expect(revised_submission.revision_number).to eq(major_revisions_requested_submission.revision_number + 1)
    end
    
    it "creates a submission that is not archived" do
      expect(revised_submission.archived).to eq(false)
    end
    
    it "creates a submission with no area editor comments" do
      expect(revised_submission.area_editor_comments_for_managing_editors).to be_nil
      expect(revised_submission.area_editor_comments_for_author).to be_nil
    end
  end

  describe "#set_auth_token" do
    
    let(:submission) { create(:submission) }
    before(:each) { submission.set_auth_token }
    
    it "sets auth_token to something new" do
      expect(submission.auth_token).not_to be_blank
      expect(submission.auth_token_changed?).to be_true
    end
    
    it "assigns a unique auth_token" do
      submissions_with_same_auth_token = Submission.where(auth_token: submission.auth_token)
      expect(submissions_with_same_auth_token).to be_empty
    end
  end


  # modules
  
  describe SubmissionFinders do
    before do
      @submission = create(:submission)
      @submission_assigned_to_area_editor = create(:submission_assigned_to_area_editor)      
      @submission_sent_out_for_review = create(:submission_sent_out_for_review)
      @submission_with_two_agreed_referee_assignments = create(:submission_with_two_agreed_referee_assignments)
      @submission_with_one_completed_referee_assignment = create(:submission_with_one_completed_referee_assignment)
      @submission_with_one_pending_referee_assignment_one_completed = create(:submission_with_one_pending_referee_assignment_one_completed)
      @submission_with_two_completed_referee_assignments = create(:submission_with_two_completed_referee_assignments)
      @submission_with_reject_decision_not_yet_approved = create(:submission_with_reject_decision_not_yet_approved)
      @submission_with_major_revisions_decision_not_yet_approved = create(:submission_with_major_revisions_decision_not_yet_approved)
      @submission_with_minor_revisions_decision_not_yet_approved = create(:submission_with_minor_revisions_decision_not_yet_approved)
      @submission_with_accept_decision_not_yet_approved = create(:submission_with_accept_decision_not_yet_approved)
      @desk_rejected_submission = create(:desk_rejected_submission)
      @rejected_after_review_submission = create(:rejected_after_review_submission)
      @major_revisions_requested_submission = create(:major_revisions_requested_submission)
      @accepted_submission = create(:accepted_submission)
    end

    describe ".internal_review_reminder_needed" do
          
      context "when one submission is in initial review" do
        it "returns 0 submissions" do
          expect(Submission.internal_review_reminder_needed.count).to eq(0)
        end
      end
      
      context "when one submission is in initial review, is past due" do
        before do
          area_editor_assignment = @submission_assigned_to_area_editor.area_editor_assignment
          area_editor_assignment.update_attributes(updated_at: (JournalSettings.days_for_initial_review + 0.1).days.ago)
        end
        
        it "returns that submission" do
          expect(Submission.internal_review_reminder_needed).to eq([@submission_assigned_to_area_editor])
        end
      end
      
      context "when one submission is in initial review, is past due, a reminder has already been sent" do
        before do
          area_editor_assignment = @submission_assigned_to_area_editor.area_editor_assignment
          area_editor_assignment.update_attributes(created_at: JournalSettings.days_for_initial_review.days.ago)
          NotificationMailer.remind_ae_internal_review_overdue(@submission_assigned_to_area_editor).save_and_deliver
        end
                     
        it "returns 0 submissions" do
          expect(Submission.internal_review_reminder_needed.count).to eq(0)
        end
      end
      
      context "when one submission is in initial review, is past due, a reminder has been sent, but more than 3 days ago" do
        before do
          area_editor_assignment = @submission_assigned_to_area_editor.area_editor_assignment
          area_editor_assignment.update_attributes(updated_at: (JournalSettings.days_for_initial_review + 0.1).days.ago)
          NotificationMailer.remind_ae_internal_review_overdue(@submission_assigned_to_area_editor)
                            .save_and_deliver
                            .update_attributes(created_at: 3.1.days.ago)
        end
                     
        it "returns 1 submissions" do
          expect(Submission.internal_review_reminder_needed.count).to eq(1)
        end
      end  
    end
    
    describe ".area_editor_decision_based_on_external_reviews_overdue" do
      
      context "when two submissions have all reports completed (first has one report, second has two),\
               no decision" do
        it "returns no submissions" do
          expect(Submission.area_editor_decision_based_on_external_reviews_overdue).to match_array([])
        end
      end
      
      context "when two submissions have all reports completed (first has one report, second has two),\
              no decision, the first has been waiting #{JournalSettings.days_after_reports_completed_to_submit_decision} days" do
        before(:each) do
          ra = @submission_with_one_completed_referee_assignment.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
        end
        
        it "returns no submissions" do # not enough reports
          expect(Submission.area_editor_decision_based_on_external_reviews_overdue).to be_empty
        end        
      end
      
      context "when two submissions have all reports completed (first has one report, second has two),\
               no decision, both have been waiting #{JournalSettings.days_after_reports_completed_to_submit_decision} days" do
        before(:each) do
          ra = @submission_with_one_completed_referee_assignment.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          
          ra = @submission_with_two_completed_referee_assignments.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          
          ra = @submission_with_two_completed_referee_assignments.referee_assignments.last
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)          
        end
        
        it "returns just the second submission" do
          expect(Submission.area_editor_decision_based_on_external_reviews_overdue).to match_array([@submission_with_two_completed_referee_assignments])
        end        
      end
      
      context "when two submissions have all reports completed (first has one report, second has two),\
               no decision, both have been waiting #{JournalSettings.days_after_reports_completed_to_submit_decision} days,\
               a reminder has been sent for the one with two reports" do
        before(:each) do          
          ra = @submission_with_one_completed_referee_assignment.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          
          ra = @submission_with_two_completed_referee_assignments.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          
          ra = @submission_with_two_completed_referee_assignments.referee_assignments.last
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)

          NotificationMailer.remind_ae_decision_based_on_external_reviews_overdue(@submission_with_two_completed_referee_assignments).save_and_deliver        end
        
        it "returns no submissions" do
          expect(Submission.area_editor_decision_based_on_external_reviews_overdue).to be_empty
        end        
      end
      
      context "when two submissions have all reports completed (first has one report, second has two),\
               no decision, both have been waiting #{JournalSettings.days_after_reports_completed_to_submit_decision} days,\
               a reminder has been sent for the one with two reports, but more than 2 days ago" do
        before(:each) do          
          ra = @submission_with_one_completed_referee_assignment.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          
          ra = @submission_with_two_completed_referee_assignments.referee_assignments.first
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          
          ra = @submission_with_two_completed_referee_assignments.referee_assignments.last
          ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)

          NotificationMailer.remind_ae_decision_based_on_external_reviews_overdue(@submission_with_two_completed_referee_assignments)
                            .save_and_deliver
                            .update_attributes(created_at: 2.1.days.ago)
        end
        
        it "returns just the second submissions" do
          expect(Submission.area_editor_decision_based_on_external_reviews_overdue).to match_array([@submission_with_two_completed_referee_assignments])
        end        
      end
    end
    
    describe ".area_editor_assignment_reminder_needed" do
      
      context "when one submission has no area editor" do
        it "returns no submissions" do
          expect(Submission.area_editor_assignment_reminder_needed).to be_empty
        end
      end
      
      context "when one submission has no area editor, it's been waiting #{JournalSettings.days_to_assign_area_editor}" do
        it "returns just that submission" do
          @submission.update_attributes(created_at: (JournalSettings.days_to_assign_area_editor + 0.1).days.ago)
          expect(Submission.area_editor_assignment_reminder_needed).to match_array([@submission])
        end
      end
      
      context "when one submission has no area editor, another has an area editor, both have been waiting #{JournalSettings.days_to_assign_area_editor}" do
        it "returns just the first submission" do
          @submission.update_attributes(created_at: (JournalSettings.days_to_assign_area_editor + 0.1).days.ago)
          @submission_assigned_to_area_editor.update_attributes(created_at: (JournalSettings.days_to_assign_area_editor + 0.1).days.ago)
          expect(Submission.area_editor_assignment_reminder_needed).to match_array([@submission])
        end
      end
      
      context "when one submission has no area editor, another has an area editor, both have been waiting #{JournalSettings.days_to_assign_area_editor}, a reminder has been sent for the first" do
        before(:each) do
          @submission.update_attributes(created_at: JournalSettings.days_to_assign_area_editor.days.ago)
          @submission_assigned_to_area_editor.update_attributes(created_at: JournalSettings.days_to_assign_area_editor.days.ago)
          
          NotificationMailer.remind_managing_editors_assignment_overdue(@submission).save_and_deliver
        end

        it "returns no submissions" do
          expect(Submission.area_editor_assignment_reminder_needed).to be_empty
        end
      end
      
      context "when one submission has no area editor, another has an area editor, both have been waiting #{JournalSettings.days_to_assign_area_editor}, a reminder has been sent for the first but more than 1 day ago" do
        before do
          @submission.update_attributes(created_at: (JournalSettings.days_to_assign_area_editor + 0.1).days.ago)
          @submission_assigned_to_area_editor.update_attributes(created_at: (JournalSettings.days_to_assign_area_editor + 0.1).days.ago)
          
          NotificationMailer.remind_managing_editors_assignment_overdue(@submission)
                            .save_and_deliver
                            .update_attributes(created_at: 1.1.days.ago)
        end

        it "returns the first submissions" do
          expect(Submission.area_editor_assignment_reminder_needed).to match_array([@submission])
        end
      end
    end
    
    describe ".decision_approval_reminder_needed" do
      
      context "when four submissions have decisions not yet approved" do
        it "returns no submissions" do
          expect(Submission.decision_approval_reminder_needed).to be_empty
        end
      end
      
      context "when four submissions have decisions not yet approved, two of those awaiting approval #{JournalSettings.days_to_remind_overdue_decision_approval} days" do
        before do
          @submission_with_reject_decision_not_yet_approved.update_attributes(decision_entered_at: (JournalSettings.days_to_remind_overdue_decision_approval + 0.1).days.ago)
          @submission_with_minor_revisions_decision_not_yet_approved.update_attributes(decision_entered_at: (JournalSettings.days_to_remind_overdue_decision_approval + 0.1).days.ago)
        end
        
        it "returns those two submissions" do
          expect(Submission.decision_approval_reminder_needed).to match_array([@submission_with_reject_decision_not_yet_approved, @submission_with_minor_revisions_decision_not_yet_approved])
        end
      end
      
      context "when four submissions have decisions not yet approved, two of those awaiting approval #{JournalSettings.days_to_remind_overdue_decision_approval} days, a reminder has been sent for one of those" do
        before do
          @submission_with_reject_decision_not_yet_approved.update_attributes(decision_entered_at: (JournalSettings.days_to_remind_overdue_decision_approval + 0.1).days.ago)
          @submission_with_minor_revisions_decision_not_yet_approved.update_attributes(decision_entered_at: (JournalSettings.days_to_remind_overdue_decision_approval + 0.1).days.ago)
          
          NotificationMailer.remind_managing_editors_decision_approval_overdue(@submission_with_minor_revisions_decision_not_yet_approved).save_and_deliver
        end
        
        it "returns only the submission with no reminder" do
          expect(Submission.decision_approval_reminder_needed).to match_array([@submission_with_reject_decision_not_yet_approved])
        end
      end
      
      context "when four submissions have decisions not yet approved, two of those awaiting approval #{JournalSettings.days_to_remind_overdue_decision_approval} days, a reminder has been sent for one of those, but more than 1 day ago" do
        before do
          @submission_with_reject_decision_not_yet_approved.update_attributes(decision_entered_at: (JournalSettings.days_to_remind_overdue_decision_approval + 0.1).days.ago)
          @submission_with_minor_revisions_decision_not_yet_approved.update_attributes(decision_entered_at: (JournalSettings.days_to_remind_overdue_decision_approval + 0.1).days.ago)
          
          NotificationMailer.remind_managing_editors_decision_approval_overdue(@submission_with_minor_revisions_decision_not_yet_approved)
                            .save_and_deliver
                            .update_attributes(created_at: 1.1.days.ago)
        end
        
        it "returns the two awaiting approval" do
          expect(Submission.decision_approval_reminder_needed).to match_array([@submission_with_reject_decision_not_yet_approved, @submission_with_minor_revisions_decision_not_yet_approved])
        end
      end
      
    end
    
  end

  describe SubmissionStatusCheckers do
      
    let(:submission) { create(:submission) }
    let(:submission_assigned_to_area_editor) { create(:submission_assigned_to_area_editor) }
    let(:submission_sent_for_review_without_area_editor) { create(:submission_sent_for_review_without_area_editor) }    
    let(:submission_sent_out_for_review) { create(:submission_sent_out_for_review) }
    let(:submission_with_two_agreed_referee_assignments) { create(:submission_with_two_agreed_referee_assignments) }
    let(:submission_with_one_completed_referee_assignment) { create(:submission_with_one_completed_referee_assignment) }
    let(:submission_with_two_completed_referee_assignments) { create(:submission_with_two_completed_referee_assignments) }
    let(:submission_with_reject_decision_not_yet_approved) { create(:submission_with_reject_decision_not_yet_approved) }
    let(:submission_with_major_revisions_decision_not_yet_approved) { create(:submission_with_major_revisions_decision_not_yet_approved) }
    let(:submission_with_minor_revisions_decision_not_yet_approved) { create(:submission_with_minor_revisions_decision_not_yet_approved) }
    let(:submission_with_accept_decision_not_yet_approved) { create(:submission_with_accept_decision_not_yet_approved) }
    let(:desk_rejected_submission) { create(:desk_rejected_submission) }
    let(:rejected_after_review_submission) { create(:rejected_after_review_submission) }
    let(:major_revisions_requested_submission) { create(:major_revisions_requested_submission) }
    let(:accepted_submission) { create(:accepted_submission) }

    # stage

    describe "#pre_initial_review?" do
      it "returns true when no area editor or referee is assigned" do
        expect(submission.pre_initial_review?).to be_true
      end

      it "returns false when an area editor is assigned" do
        expect(submission_assigned_to_area_editor.pre_initial_review?).to eq(false)
      end

      it "returns false when a referee is assigned" do
        expect(submission_sent_for_review_without_area_editor.pre_initial_review?).to eq(false)
      end
    end
  
    describe "#in_initial_review?" do
      it "returns false when no area editor is assigned" do
        expect(submission.in_initial_review?).to eq(false)
      end
      
      it "returns true when an area editor is assigned" do
        expect(submission_assigned_to_area_editor.in_initial_review?).to be_true
      end
      
      it "returns false once a referee is assigned" do
        expect(submission_sent_out_for_review.in_initial_review?).to eq(false)
        expect(submission_sent_for_review_without_area_editor.in_initial_review?).to eq(false)
      end
      
      it "returns false once a decision is entered" do
        expect(desk_rejected_submission.in_initial_review?).to eq(false)
      end
    end
    
    describe "#in_external_review?" do
      it "returns false when no referees have been assigned" do
        expect(submission_assigned_to_area_editor.in_external_review?).to eq(false)
      end
      
      it "returns true when a referee is assigned" do
        expect(submission_sent_for_review_without_area_editor.in_external_review?).to be_true
        expect(submission_sent_out_for_review.in_external_review?).to be_true
      end
      
      it "returns false once enough reports are completed" do
        expect(submission_with_two_completed_referee_assignments.in_external_review?).to eq(false)
      end
    end
    
    describe "#post_external_review?" do
      it "returns false when no reports are completed" do
        expect(submission_with_two_agreed_referee_assignments.post_external_review?).to be false
      end
      
      it "returns true when enough reports have been completed" do
        expect(submission_with_one_completed_referee_assignment.post_external_review?).to eq(false)
        expect(submission_with_two_completed_referee_assignments.post_external_review?).to be_true
      end
      
      it "returns false once a decision is entered" do
        expect(submission_with_reject_decision_not_yet_approved.post_external_review?).to eq(false)
        expect(submission_with_minor_revisions_decision_not_yet_approved.post_external_review?).to eq(false)
      end      
    end
    
    describe "#review_complete?" do
      it "returns false when no decision is entered" do
        expect(submission_with_two_completed_referee_assignments.review_complete?).to eq(false)
      end
      
      it "returns true when a decision is entered but not yet approved" do
        expect(submission_with_accept_decision_not_yet_approved.review_complete?).to be_true
      end
      
      it "returns false when a decision is approved" do
        expect(desk_rejected_submission.review_complete?).to eq(false)
      end
    end
    
    describe "#review_approved?" do
      it "returns false when there is no decision" do
        expect(submission_with_accept_decision_not_yet_approved.review_approved?).to eq(false)
      end
      
      it "returns false when the decision is not yet approved" do
        expect(accepted_submission.review_approved?).to be_true
      end
    end
    
    # initial review
    
    describe "#area_editor_assigned?" do
      it "returns false when no area editor is assigned" do
        expect(submission.area_editor_assigned?).to eq(false)
      end
      
      it "returns true when an area editor is assigned" do
        expect(submission_assigned_to_area_editor.area_editor_assigned?).to be_true
      end
    end
    
    describe "#area_editor_assignment_overdue?" do
      
      context "when area editor assignment is not yet overdue" do
        it "returns false" do
          expect(submission.area_editor_assignment_overdue?).to eq(false)
        end
      end
      
      context "when area editor assignment is overdue" do
        before { submission.update_attributes(created_at: JournalSettings.days_to_assign_area_editor.days.ago) }
        it "returns true" do
          expect(submission.area_editor_assignment_overdue?).to be_true
        end
      end
    end
    
    describe "#initial_review_overdue?" do
      context "when no area editor assigned" do
        it "returns false" do
          expect(submission.initial_review_overdue?).to eq(false)
        end
      end
      
      context "when area editor just assigned" do
        it "returns false" do
          expect(submission_assigned_to_area_editor.initial_review_overdue?).to eq(false)
        end
      end
      
      context "when area editor assigned JournalSettings.days_for_initial_review days ago" do
        it "returns true" do
          submission_assigned_to_area_editor.update_attributes(created_at: JournalSettings.days_for_initial_review.days.ago)
          expect(submission_assigned_to_area_editor.initial_review_overdue?).to be_true
        end
      end
      
      context "when area editor assigned JournalSettings.days_for_initial_review days ago, but referee assigned" do
        it "returns false" do
          submission_sent_out_for_review.update_attributes(created_at: JournalSettings.days_for_initial_review.days.ago)
          expect(submission_sent_out_for_review.initial_review_overdue?).to eq(false)
        end
      end
      
      context "when area editor assigned JournalSettings.days_for_initial_review days ago, but decision entered" do
        it "returns false" do
          submission_with_reject_decision_not_yet_approved.update_attributes(created_at: JournalSettings.days_for_initial_review.days.ago)
          expect(submission_with_reject_decision_not_yet_approved.initial_review_overdue?).to eq(false)
        end
      end
    end
    
    # external review
    
    describe "#referee_assigned?" do
      it "returns false when no referees are assigned" do
        expect(submission_assigned_to_area_editor.referee_assigned?).to eq(false)
      end
      
      it "returns true when at least one referee is assigned" do
        expect(submission_sent_for_review_without_area_editor.referee_assigned?).to be_true
      end
    end
    
    describe "#external_review?" do
      it "returns true if there are non-canceled referee assignments" do
        expect(submission_sent_out_for_review.external_review?).to be_true
      end
      
      it "returns false if there are no referee assignments" do
        expect(submission_assigned_to_area_editor.external_review?).to eq(false)
      end
      
      it "returns false if there are only canceled referee assignments" do
        submission_sent_out_for_review.referee_assignments.each { |ra| ra.cancel! }
        expect(submission_sent_out_for_review.external_review?).to eq(false)
      end
    end
    
    describe "#has_incomplete_referee_assignments?" do
      it "returns true if there is a non-canceled, non-declined, non-complete referee assignment" do
        expect(submission_sent_out_for_review.has_incomplete_referee_assignments?).to be_true
      end
      
      it "returns false if all referee assignments are canceled, declined, or complete" do
        submission_with_two_agreed_referee_assignments.referee_assignments.each do |ra|
          ra.cancel! unless !ra.agreed? || ra.canceled? || ra.report_completed?
        end

        expect(submission_with_two_agreed_referee_assignments.has_incomplete_referee_assignments?).to eq(false)
      end
    end
    
    describe "#last_report_due_at" do
      it "returns the due_at of the referee assignment with the latest due date (excluding canceled and declined assignments)" do
        submission_with_two_agreed_referee_assignments.referee_assignments.reverse.each_with_index do |ra, i|
          ra.update_attributes(report_due_at: i.days.from_now)
        end        
        third = submission_with_two_agreed_referee_assignments.referee_assignments[3].reload # first and second are declined/canceled
        
        expect(submission_with_two_agreed_referee_assignments.last_report_due_at).to eq(third.report_due_at)
      end
    end
    
    describe "#last_report_completed_at" do
      it "returns the report_completed_at of the most recently completed report" do
        submission = submission_with_two_completed_referee_assignments
        first_assignment = submission.referee_assignments.first
        second_assignment = submission.referee_assignments.last
        
        first_assignment.update_attributes(report_completed_at: 1.days.ago)
        second_assignment.update_attributes(report_completed_at: 2.days.ago)

        expect(submission.last_report_completed_at.to_s).to eq(first_assignment.report_completed_at.to_s)
      end
    end
    
    describe "#has_enough_referee_assignments?" do
      it "returns true if the number of non-canceled, non-declined referee assignments is or exceeds JournalSettings.number_of_reports_expected" do
        expect(submission_with_two_agreed_referee_assignments.has_enough_referee_assignments?).to be_true
      end
      
      it "returns true if not in external review" do
        expect(submission.has_enough_referee_assignments?).to be_true
      end
      
      it "returns false otherwise" do
        expect(submission_sent_out_for_review.has_enough_referee_assignments?).to eq(false)
      end
    end

    describe "#number_of_complete_reports" do
      it "returns the number of completed, non-canceled reports" do
        expect(submission_assigned_to_area_editor.number_of_complete_reports).to eq(0)
        expect(submission_sent_out_for_review.number_of_complete_reports).to eq(0)
        expect(submission_with_two_agreed_referee_assignments.number_of_complete_reports).to eq(1)
        expect(submission_with_one_completed_referee_assignment.number_of_complete_reports).to eq(1)
        expect(submission_with_two_completed_referee_assignments.number_of_complete_reports).to eq(2)
        expect(submission_with_reject_decision_not_yet_approved.number_of_complete_reports).to eq(2)
        expect(submission_with_major_revisions_decision_not_yet_approved.number_of_complete_reports).to eq(2)
        expect(desk_rejected_submission.number_of_complete_reports).to eq(0)
        expect(rejected_after_review_submission.number_of_complete_reports).to eq(2)
      end
    end
    
    describe "#number_of_reports_still_needed" do
      it "returns the number of reports still needed" do
        expect(submission_assigned_to_area_editor.number_of_reports_still_needed).to eq(2)
        expect(submission_sent_out_for_review.number_of_reports_still_needed).to eq(2)
        expect(submission_with_two_agreed_referee_assignments.number_of_reports_still_needed).to eq(1)
        expect(submission_with_one_completed_referee_assignment.number_of_reports_still_needed).to eq(1)
        expect(submission_with_two_completed_referee_assignments.number_of_reports_still_needed).to eq(0)
        expect(submission_with_reject_decision_not_yet_approved.number_of_reports_still_needed).to eq(0)
      end
    end

    describe "#has_enough_reports?" do
      it "returns true if the number of completed, non-canceled reports is or exceeds JournalSettings.number_of_reports_expected" do
        expect(submission_with_two_completed_referee_assignments.has_enough_reports?).to be_true
      end
      
      it "returns false if the number of completed reports is less than JournalSettings.number_of_reports_expected" do
        expect(submission_with_one_completed_referee_assignment.has_enough_reports?).to eq(false)
      end
    end
    
    describe "#needs_more_reports?" do
      it "returns true if sent for external review and doesn't have JournalSettings.number_of_reports_expected reports" do
        expect(submission_with_two_agreed_referee_assignments.needs_more_reports?).to be_true
        expect(submission_with_one_completed_referee_assignment.needs_more_reports?).to be_true
      end
      
      it "returns false if not sent for external review" do
        expect(submission.has_enough_reports?).to eq(false)
      end
      
      it "returns false if sent for external review and has JournalSettings.number_of_reports_expected reports" do
        expect(submission_with_two_completed_referee_assignments.needs_more_reports?).to eq(false)
      end
    end
    
    describe "#has_overdue_referee_assignments?" do
      it "returns true if at least one pending referee assignment is overdue (JournalSettings.days_for_external_review)" do
        incomplete_assignment = submission_with_two_agreed_referee_assignments.referee_assignments[2]
        incomplete_assignment.update_attributes(report_due_at: 1.second.ago)
        
        expect(submission_with_two_agreed_referee_assignments.has_overdue_referee_assignments?).to be_true
      end
      
      it "returns false if no referee assignments are overdue" do
        expect(submission_with_two_agreed_referee_assignments.has_overdue_referee_assignments?).to eq(false)
      end
      
      it "returns false if not in external review" do
        submission_with_two_completed_referee_assignments.referee_assignments.each do |ra|
          ra.update_attributes(report_due_at: 1.second.ago)
        end
        
        expect(submission_with_two_completed_referee_assignments.has_overdue_referee_assignments?).to eq(false)
      end
    end
    
    describe "#referee_reports_complete?" do
      it "returns true if all referee reports care completed" do
        expect(submission_with_two_completed_referee_assignments.referee_reports_complete?).to be_true
      end
      
      it "returns false if at least one referee report is not complete" do
        expect(submission_with_two_agreed_referee_assignments.referee_reports_complete?).to eq(false)
      end
    end
    
    # post-external review
  
    describe "#area_editor_decision_based_on_external_review_overdue?" do
      context "when the last report was completed more than days_after_reports_completed_to_submit_decision days ago" do
        before do
          submission_with_two_completed_referee_assignments.referee_assignments.each do |ra|
            ra.update_attributes(report_completed_at: JournalSettings.days_after_reports_completed_to_submit_decision.days.ago)
          end
        end        
        it "returns true" do
          expect(submission_with_two_completed_referee_assignments.area_editor_decision_based_on_external_review_overdue?).to be_true
        end
      end
      
      context "when the last report was completed less than days_after_reports_completed_to_submit_decision days ago" do
        it "returns false" do
          expect(submission_with_two_completed_referee_assignments.area_editor_decision_based_on_external_review_overdue?).to eq(false)
        end
      end
    end
    
    describe "#decision_approval_overdue?" do
      context "when the decision was entered more than days_to_remind_overdue_decision_approval days ago" do
        before do
          submission_with_reject_decision_not_yet_approved.update_attributes(decision_entered_at: JournalSettings.days_to_remind_overdue_decision_approval.days.ago)
        end
        it "returns true" do
          expect(submission_with_reject_decision_not_yet_approved.decision_approval_overdue?).to be_true
        end
      end
      
      context "when the decision was entered less than days_to_remind_overdue_decision_approval days ago" do
        it "returns false" do
          expect(submission_with_reject_decision_not_yet_approved.decision_approval_overdue?).to eq(false)
        end
      end
      
      context "when review is not complete" do
        it "returns false" do
          expect(submission_with_two_completed_referee_assignments.decision_approval_overdue?).to eq(false)
        end
      end
    end
    
    # display
    
    describe "#display_status_for_editors" do
      context "when awaiting area editor assignment" do
        it "returns 'Needs area editor'" do
          expect(submission.display_status_for_editors).to eq('Needs area editor')
        end
      end
      
      context "when area editor assigned, no decision entered, no referees assigned" do
        it "returns 'Initial review'" do
          expect(submission_assigned_to_area_editor.display_status_for_editors).to eq('Initial review')
        end
      end
      
      context "when referees assigned but a pending report is incomplete" do
        it "returns 'Awaiting reports'" do
          expect(submission_sent_out_for_review.display_status_for_editors).to eq('Awaiting reports')
          expect(submission_with_two_agreed_referee_assignments.display_status_for_editors).to eq('Awaiting reports')
        end
      end
      
      context "when enough reports are complete, no decision entered" do
        it "returns 'Needs decision'" do
          expect(submission_with_two_completed_referee_assignments.display_status_for_editors).to eq('Needs decision')
        end
      end
      
      context "when decision is awaiting approval" do
        it "returns 'Decision needs approval'" do
          expect(submission_with_major_revisions_decision_not_yet_approved.display_status_for_editors).to eq('Decision needs approval')
        end
      end
      
      context "when decision is approved" do
        it "returns the decision" do
          expect(desk_rejected_submission.display_status_for_editors).to match(Decision::REJECT)
          expect(major_revisions_requested_submission.display_status_for_editors).to match(Decision::MAJOR_REVISIONS)
        end
      end
    end
    
  end
  
  describe SubmissionReminders do
  
    describe ".send_overdue_internal_review_reminders" do
    
      context "when no internal reviews are overdue" do
        before do
          @submission = create(:submission_assigned_to_area_editor)
          Submission.send_overdue_internal_review_reminders
        end
      
        it "sends no reminder emails" do
          expect(deliveries).not_to include_email(to: @submission.area_editor.email, subject_begins: 'Overdue Internal Review')
          expect(SentEmail.all).not_to include_record(to: @submission.area_editor.email, subject_begins: 'Overdue Internal Review')
        end
      end
    
      context "when one internal review is overdue" do
        before do
          @submission = create(:submission_assigned_to_area_editor)
          updated_at = Time.current - JournalSettings.days_for_initial_review.days - JournalSettings.days_to_remind_area_editor.days - 1.second
          @submission.area_editor_assignment.update_attributes(updated_at: updated_at)
          Submission.send_overdue_internal_review_reminders
        end
      
        it "sends one reminder email" do
          expect(deliveries).to include_email(subject_begins: 'Overdue Internal Review',
                                              to: @submission.area_editor.email,
                                              cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Overdue Internal Review',
                                                    to: @submission.area_editor.email,
                                                    cc: managing_editor.email)
        end
      end
    
      context "when two internal reviews are overdue" do
        before do
          @submission1 = create(:submission_assigned_to_area_editor)
          updated_at = Time.current - JournalSettings.days_for_initial_review.days - JournalSettings.days_to_remind_area_editor.days - 1.second
          @submission1.area_editor_assignment.update_attributes(updated_at: updated_at)

          @submission2 = create(:submission_assigned_to_area_editor)
          updated_at = Time.current - JournalSettings.days_for_initial_review.days - JournalSettings.days_to_remind_area_editor.days - 1.second
          @submission2.area_editor_assignment.update_attributes(updated_at: updated_at)
        
          Submission.send_overdue_internal_review_reminders
        end
      
        it "sends two reminder emails" do
          expect(deliveries).to include_email(subject_begins: 'Overdue Internal Review',
                                              to: @submission1.area_editor.email,
                                              cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Overdue Internal Review',
                                                    to: @submission1.area_editor.email,
                                                    cc: managing_editor.email)
                                                  
          expect(deliveries).to include_email(subject_begins: 'Overdue Internal Review',
                                              to: @submission2.area_editor.email,
                                              cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Overdue Internal Review',
                                                    to: @submission2.area_editor.email,
                                                    cc: managing_editor.email)
        end
      end
    end
  
    describe ".send_overdue_decision_based_on_external_review_reminders" do
    
      context "when no submissions have all reports complete" do
        before do
          @submission = create(:submission_with_two_completed_referee_assignments)
          Submission.send_overdue_decision_based_on_external_review_reminders
        end
      
        it "sends no reminder emails" do
          expect(deliveries).not_to include_email(subject_begins: 'Overdue Decision',
                                                  to: @submission.area_editor.email,
                                                  cc: managing_editor.email)
          expect(SentEmail.all).not_to include_record(subject_begins: 'Overdue Decision',
                                                        to: @submission.area_editor.email,
                                                        cc: managing_editor.email)
        end
      end
    
      context "when one submission has all reports complete" do
        before do
          @submission = create(:submission_with_two_completed_referee_assignments)
          completed_at = Time.current - JournalSettings.days_after_reports_completed_to_submit_decision.days - 1.second
          @submission.referee_assignments.each do |assignment|
            assignment.update_attributes(report_completed_at: completed_at)
          end
          @other_submission = create(:submission_with_two_completed_referee_assignments)
          Submission.send_overdue_decision_based_on_external_review_reminders
        end
      
        it "sends a reminder email to that area editor" do
          expect(deliveries).to include_email(subject_begins: 'Overdue Decision',
                                                  to: @submission.area_editor.email,
                                                  cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Overdue Decision',
                                                        to: @submission.area_editor.email,
                                                        cc: managing_editor.email)
        end
      
        it "doesn't send a reminder to other area editors" do
          expect(deliveries).not_to include_email(to: @other_submission.area_editor.email, subject_begins: 'Overdue Decision')
          expect(SentEmail.all).not_to include_record(to: @other_submission.area_editor.email, subject_begins: 'Overdue Decision')
        end
      end
    
      context "when two submissions have all reports complete" do
        before do
          @submission1 = create(:submission_with_two_completed_referee_assignments)
          completed_at = Time.current - JournalSettings.days_after_reports_completed_to_submit_decision.days - 1.second
          @submission1.referee_assignments.each do |assignment|
            assignment.update_attributes(report_completed_at: completed_at)
          end
        
          @submission2 = create(:submission_with_two_completed_referee_assignments)
          @submission2.referee_assignments.each do |assignment|
            assignment.update_attributes(report_completed_at: completed_at)
          end
        
          Submission.send_overdue_decision_based_on_external_review_reminders
        end
      
        it "sends reminder emails to both area editors" do
          expect(deliveries).to include_email(subject_begins: 'Overdue Decision',
                                                  to: @submission1.area_editor.email,
                                                  cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Overdue Decision',
                                                        to: @submission1.area_editor.email,
                                                        cc: managing_editor.email)
        
          expect(deliveries).to include_email(subject_begins: 'Overdue Decision',
                                                  to: @submission2.area_editor.email,
                                                  cc: managing_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Overdue Decision',
                                                        to: @submission2.area_editor.email,
                                                        cc: managing_editor.email)
        end
      end
    end
  
    describe ".send_overdue_area_editor_assignment_reminders" do
    
      context "when no submissions are overdue for assignment to an area editor" do
        before do
          @submission = create(:submission)
          Submission.send_overdue_area_editor_assignment_reminders
        end
      
        it "sends no reminder emails" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).not_to include_email(subject_begins: 'Reminder: Assignment Needed')
            expect(SentEmail.all).not_to include_record(subject_begins: 'Reminder: Assignment Needed')
          end
        end
      end
    
      context "when one submission is overdue for assignment to an area editor" do
        before do
          @submission = create(:submission)
          created_at = Time.current - JournalSettings.days_to_assign_area_editor.days - 1.second
          @submission.update_attributes(created_at: created_at)
          @other_submission = create(:submission)
          Submission.send_overdue_area_editor_assignment_reminders
        end
      
        it "sends a reminder email to each managing editor" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).to include_email(to: managing_editor.email, 
                                                subject_begins: 'Reminder: Assignment Needed',
                                                body_includes: @submission.title)
            expect(SentEmail.all).to include_record(to: managing_editor.email, 
                                                      subject_begins: 'Reminder: Assignment Needed',
                                                      body_includes: @submission.title)
          end
        end
      
        it "doesn't send any reminders about submissions not yet overdue" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).not_to include_email(to: managing_editor.email, 
                                                    subject_begins: 'Reminder: Assignment Needed',
                                                    body_includes: @other_submission.title)
            expect(SentEmail.all).not_to include_record(to: managing_editor.email, 
                                                          subject_begins: 'Reminder: Assignment Needed',
                                                          body_includes: @other_submission.title)
          end
        end
      end
    
      context "when two submissions are overdue for assignment to an area editor" do
        before do
          @submission1 = create(:submission)
          created_at = Time.current - JournalSettings.days_to_assign_area_editor.days - 1.second
          @submission1.update_attributes(created_at: created_at)
        
          @submission2 = create(:submission)
          created_at = Time.current - JournalSettings.days_to_assign_area_editor.days - 1.second
          @submission2.update_attributes(created_at: created_at)
        
          Submission.send_overdue_area_editor_assignment_reminders
        end
      
        it "sends reminders about both submissions to each managing editor" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).to include_email(to: managing_editor.email, 
                                                subject_begins: 'Reminder: Assignment Needed',
                                                body_includes: @submission1.title)
            expect(SentEmail.all).to include_record(to: managing_editor.email, 
                                                      subject_begins: 'Reminder: Assignment Needed',
                                                      body_includes: @submission1.title)

            expect(deliveries).to include_email(to: managing_editor.email,
                                                subject_begins: 'Reminder: Assignment Needed',
                                                body_includes: @submission2.title)
            expect(SentEmail.all).to include_record(to: managing_editor.email,
                                                      subject_begins: 'Reminder: Assignment Needed',
                                                      body_includes: @submission2.title)
          end
        end
      end
    end
  
    describe ".send_decision_approval_overdue_reminders" do
    
      context "when no decisions are overdue for approval" do
        before do
          @submission = create(:submission_with_reject_decision_not_yet_approved)
          Submission.send_decision_approval_overdue_reminders
        end
      
        it "sends no reminder emails" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).not_to include_email(to: managing_editor.email, subject_begins: 'Reminder: Decision Needs Approval')
            expect(SentEmail.all).not_to include_record(to: managing_editor.email, subject_begins: 'Reminder: Decision Needs Approval')
          end
        end
      end
    
      context "when one decision is overdue for approval" do
        before do
          @submission = create(:submission_with_reject_decision_not_yet_approved)
          decision_entered_at = Time.current - JournalSettings.days_to_remind_overdue_decision_approval.days - 1.second
          @submission.update_attributes(decision_entered_at: decision_entered_at)
        
          @other_submission = create(:submission_with_reject_decision_not_yet_approved)
        
          Submission.send_decision_approval_overdue_reminders
        end
      
        it "sends a reminder email to each managing editor" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).to include_email(to: managing_editor.email, 
                                                subject_begins: 'Reminder: Decision Needs Approval',
                                                body_includes: @submission.title)
            expect(SentEmail.all).to include_record(to: managing_editor.email, 
                                                      subject_begins: 'Reminder: Decision Needs Approval',
                                                      body_includes: @submission.title)
          end
        end
      
        it "doesn't send any reminders about submissions not yet overdue" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).not_to include_email(to: managing_editor.email, 
                                                    subject_begins: 'Reminder: Decision Needs Approval',
                                                    body_includes: @other_submission.title)
            expect(SentEmail.all).not_to include_record(to: managing_editor.email, 
                                                          subject_begins: 'Reminder: Decision Needs Approval',
                                                          body_includes: @other_submission.title)
          end
        end
      end
    
      context "when two submissions are overdue for assignment to an area editor" do
        before do
          @submission1 = create(:submission_with_reject_decision_not_yet_approved)
          decision_entered_at = Time.current - JournalSettings.days_to_remind_overdue_decision_approval.days - 1.second
          @submission1.update_attributes(decision_entered_at: decision_entered_at)
      
          @submission2 = create(:submission_with_reject_decision_not_yet_approved)
          decision_entered_at = Time.current - JournalSettings.days_to_remind_overdue_decision_approval.days - 1.second
          @submission2.update_attributes(decision_entered_at: decision_entered_at)
      
          Submission.send_decision_approval_overdue_reminders
        end
      
        it "sends reminders about both submissions to each managing editor" do
          User.where(managing_editor: true).each do |managing_editor|
            expect(deliveries).to include_email(to: managing_editor.email, 
                                                subject_begins: 'Reminder: Decision Needs Approval',
                                                body_includes: @submission1.title)
            expect(SentEmail.all).to include_record(to: managing_editor.email, 
                                                      subject_begins: 'Reminder: Decision Needs Approval',
                                                      body_includes: @submission1.title)

            expect(deliveries).to include_email(to: managing_editor.email,
                                                subject_begins: 'Reminder: Decision Needs Approval',
                                                body_includes: @submission2.title)
            expect(SentEmail.all).to include_record(to: managing_editor.email,
                                                      subject_begins: 'Reminder: Decision Needs Approval',
                                                      body_includes: @submission2.title)
          end
        end
      end
    end
  end
   
end
