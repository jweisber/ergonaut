# == Schema Information
#
# Table name: referee_assignments
#
#  id                        :integer          not null, primary key
#  user_id                   :integer
#  submission_id             :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  agreed                    :boolean
#  decline_comment           :text
#  auth_token                :string(255)
#  assigned_at               :datetime
#  agreed_at               :datetime
#  declined_at               :datetime
#  report_due_at             :datetime
#  canceled                  :boolean
#  comments_for_editor       :text
#  comments_for_author       :text
#  report_completed          :boolean
#  report_completed_at       :datetime
#  recommend_reject          :boolean
#  recommend_major_revisions :boolean
#  recommend_minor_revisions :boolean
#  recommend_accept          :boolean
#  referee_letter            :string(255)
#  response_due_at           :datetime
#

require 'spec_helper'

describe RefereeAssignment do

  let!(:managing_editor) { create(:managing_editor) }
  let(:referee_assignment) { build(:referee_assignment) }
  subject { referee_assignment }

  # attributes

  it { should respond_to(:referee) }
  it { should respond_to(:submission) }
  it { should respond_to(:emails) }
  it { should respond_to(:agreed) }
  it { should respond_to(:decline_comment) }
  it { should respond_to(:auth_token) }
  it { should respond_to(:assigned_at) }
  it { should respond_to(:agreed_at) }
  it { should respond_to(:declined_at) }
  it { should respond_to(:report_due_at) }
  it { should respond_to(:canceled) }
  it { should respond_to(:recommendation) }
  it { should respond_to(:comments_for_editor) }
  it { should respond_to(:attachment_for_editor) }
  it { should respond_to(:comments_for_author) }
  it { should respond_to(:attachment_for_author) }
  it { should respond_to(:report_completed) }
  it { should respond_to(:recommend_reject) }
  it { should respond_to(:recommend_major_revisions) }
  it { should respond_to(:recommend_minor_revisions) }
  it { should respond_to(:recommend_accept) }
  it { should respond_to(:referee_letter) }
  it { should respond_to(:response_due_at) }
  it { should respond_to(:custom_email_opening) }
  it { should be_valid }


  # defaults

  its(:agreed) { should be_nil }
  its(:report_completed) { should eq(false) }
  its(:recommend_reject) { should eq(false) }
  its(:recommend_major_revisions) { should eq(false) }
  its(:recommend_minor_revisions) { should eq(false) }
  its(:recommend_accept) { should eq(false) }
  its(:canceled) { should eq(false) }

  context "upon creation" do
    before { referee_assignment.save }
    its(:assigned_at) { should be_within_seconds_of(Time.current) }
    its(:response_due_at) { should be_within_seconds_of(Time.current + JournalSettings.days_to_respond_to_referee_request.days) }
    its(:report_due_at) { should be_within_seconds_of(Time.current + JournalSettings.days_for_external_review.days) }
    its(:report_originally_due_at) { should eq(referee_assignment.report_due_at) }
    its(:referee_letter) { should eq('A') }
    its(:auth_token) { should have(22).characters }
  end


  # validations

  it "is not valid without a referee" do
    referee_assignment.referee = nil
    expect(referee_assignment).not_to be_valid
  end

  it "is not valid without a submission" do
    referee_assignment.submission = nil
    expect(referee_assignment).not_to be_valid
  end

  it "is not valid when attachment_for_editor is larger than 5MB" do
    referee_assignment.attachment_for_editor = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Oversize Submission.pdf'))
    expect(referee_assignment).not_to be_valid
  end

  it "is not valid when attachment_for_author is larger than 5MB" do
    referee_assignment.attachment_for_author = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Oversize Submission.pdf'))
    expect(referee_assignment).not_to be_valid
  end

  it "is not valid without a recommendation when report is completed" do
    referee_assignment.report_completed = true
    expect(referee_assignment).not_to be_valid
  end

  context "when changing the value of agreed" do

    it "is not valid if changing true -> nil" do
      referee_assignment.agreed = true
      referee_assignment.save
      referee_assignment.agreed = nil
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing true -> false" do
      referee_assignment.agreed = true
      referee_assignment.save
      referee_assignment.agreed = false
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing false -> nil" do
      referee_assignment.agreed = false
      referee_assignment.save
      referee_assignment.agreed = nil
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing false -> nil" do
      referee_assignment.agreed = false
      referee_assignment.save
      referee_assignment.agreed = true
      expect(referee_assignment).not_to be_valid
    end

    it "is valid if changed nil -> true" do
      referee_assignment.agreed = true
      expect(referee_assignment).to be_valid
    end

    it "is valid if changed nil -> false" do
      referee_assignment.agreed = false
      expect(referee_assignment).to be_valid
    end
  end

  context "when report is already completed" do
    before(:each) do
      referee_assignment.update_attributes(recommendation: Decision::REJECT, report_completed: true)
    end

    it "is not valid if recommendation changed" do
      referee_assignment.recommendation = Decision::ACCEPT
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing comments for the editor" do
      referee_assignment.comments_for_editor = 'Lorem ipusm...'
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing comments for the author" do
      referee_assignment.comments_for_author = 'Lorem ipusm...'
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing attachment for the editor" do
      referee_assignment.attachment_for_editor = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'))
      expect(referee_assignment).not_to be_valid
    end

    it "is not valid if changing attachment for the author" do
      referee_assignment.attachment_for_author = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'))
      expect(referee_assignment).not_to be_valid
    end

  end


  # instance methods

  describe "#recommendation=(rec)" do
    context "when rec is '#{Decision::REJECT}'" do
      before { referee_assignment.recommendation = Decision::REJECT }
      it "sets recommend_reject to true, all other recommend_ booleans to false" do
        expect(referee_assignment.recommend_reject).to be_true
        expect(referee_assignment.recommend_major_revisions).to eq(false)
        expect(referee_assignment.recommend_minor_revisions).to eq(false)
        expect(referee_assignment.recommend_accept).to eq(false)
      end
    end

    context "when rec is #{Decision::MAJOR_REVISIONS}" do
      before { referee_assignment.recommendation = Decision::MAJOR_REVISIONS }
      it "sets recommend_major_revisions to true, all other recommend_ booleans to false" do
        expect(referee_assignment.recommend_reject).to eq(false)
        expect(referee_assignment.recommend_major_revisions).to be_true
        expect(referee_assignment.recommend_minor_revisions).to eq(false)
        expect(referee_assignment.recommend_accept).to eq(false)
      end
    end

    context "when rec is '#{Decision::MINOR_REVISIONS}'" do
      before { referee_assignment.recommendation = Decision::MINOR_REVISIONS }
      it "sets recommend_minor_revisions to true, all other recommend_ booleans to false" do
        expect(referee_assignment.recommend_reject).to eq(false)
        expect(referee_assignment.recommend_major_revisions).to eq(false)
        expect(referee_assignment.recommend_minor_revisions).to be_true
        expect(referee_assignment.recommend_accept).to eq(false)
      end
    end

    context "when rec is '#{Decision::ACCEPT}'" do
      before { referee_assignment.recommendation = Decision::ACCEPT }
      it "sets recommend_accept to true, all other recommend_ booleans to false" do
        expect(referee_assignment.recommend_reject).to eq(false)
        expect(referee_assignment.recommend_major_revisions).to eq(false)
        expect(referee_assignment.recommend_minor_revisions).to eq(false)
        expect(referee_assignment.recommend_accept).to be_true
      end
    end
  end

  describe "#recommendation" do
    context "when recommend_reject is the only true recommend_ boolean" do
      before do
        referee_assignment.recommend_reject = true
        referee_assignment.recommend_major_revisions = false
        referee_assignment.recommend_minor_revisions = false
        referee_assignment.recommend_accept = false
      end
      it "returns '#{Decision::REJECT}'" do
        expect(referee_assignment.recommendation).to eq(Decision::REJECT)
      end
    end

    context "when recommend_major_revisions is the only true recommend_ boolean" do
      before do
        referee_assignment.recommend_reject = false
        referee_assignment.recommend_major_revisions = true
        referee_assignment.recommend_minor_revisions = false
        referee_assignment.recommend_accept = false
      end
      it "returns '#{Decision::MAJOR_REVISIONS}'" do
        expect(referee_assignment.recommendation).to eq(Decision::MAJOR_REVISIONS)
      end
    end

    context "when recommend_minor_revisions is the only true recommend_ boolean" do
      before do
        referee_assignment.recommend_reject = false
        referee_assignment.recommend_major_revisions = false
        referee_assignment.recommend_minor_revisions = true
        referee_assignment.recommend_accept = false
      end
      it "returns '#{Decision::MINOR_REVISIONS}'" do
        expect(referee_assignment.recommendation).to eq(Decision::MINOR_REVISIONS)
      end
    end

    context "when recommend_accept is the only true recommend_ boolean" do
      before do
        referee_assignment.recommend_reject = false
        referee_assignment.recommend_major_revisions = false
        referee_assignment.recommend_minor_revisions = false
        referee_assignment.recommend_accept = true
      end
      it "returns '#{Decision::ACCEPT}'" do
        expect(referee_assignment.recommendation).to eq(Decision::ACCEPT)
      end
    end
  end

  describe "#awaiting_response?" do
    context "when agreed is nil and the assignment is not canceled" do
      it "returns true" do
        expect(referee_assignment.awaiting_response?).to be_true
      end
    end

    context "when agreed is true or false" do
      before { referee_assignment.agreed = false }
      it "returns false" do
        expect(referee_assignment.awaiting_response?).to eq(false)
      end
    end

    context "when the assignment is canceled" do
      before { referee_assignment.canceled = true }
      it "returns false" do
        expect(referee_assignment.awaiting_response?).to eq(false)
      end
    end
  end

  describe "#response_overdue?" do
    context "when response_due_at has passed" do
      before { referee_assignment.response_due_at = 1.second.ago }
      it "returns true" do
        expect(referee_assignment.response_overdue?).to be_true
      end
    end

    context "when response_due_at has not passed" do
      before { referee_assignment.response_due_at = 1.year.from_now }
      it "returns false" do
        expect(referee_assignment.response_overdue?).to eq(false)
      end
    end

    context "when not awaiting a response" do
      before do
        referee_assignment.agreed = false
      end
      it "returns nil" do
        expect(referee_assignment.response_overdue?).to be_nil
      end
    end

  end

  describe "#awaiting_report?" do
    context "when the referee has agreed, the assignment has not been canceled, and the report is not complete" do
      before do
        referee_assignment.agreed = true
      end
      it "returns true" do
        expect(referee_assignment.awaiting_report?).to be_true
      end
    end

    context "when the referee has not agreed" do
      before do
        referee_assignment.agreed = false
      end
      it "returns false" do
        expect(referee_assignment.awaiting_report?).to eq(false)
      end
    end

    context "when the referee assignment is canceled" do
      before do
        referee_assignment.canceled = true
      end
      it "returns false" do
        expect(referee_assignment.awaiting_report?).to eq(false)
      end
    end

    context "when the report is complete" do
      before do
        referee_assignment = create(:completed_referee_assignment)
      end
      it "returns false" do
        expect(referee_assignment.awaiting_report?).to eq(false)
      end
    end
  end

  describe "#awaiting_action?" do
    context "when awaiting a response from the referee" do
      it "returns true" do
        expect(referee_assignment.awaiting_action?).to be_true
      end
    end

    context "when awaiting a report from the referee" do
      before do
        referee_assignment.agreed = true
      end
      it "returns true" do
        expect(referee_assignment.awaiting_action?).to be_true
      end
    end

    context "when neither awaiting a response nor a report from the referee" do
      let(:completed_referee_assignment) { create(:completed_referee_assignment) }
      it "returns false" do
        expect(completed_referee_assignment.awaiting_action?).to eq(false)
      end
    end
  end

  describe "#report_overdue?" do
    context "when the referee has agreed but not completed the report, and the due date has passed" do
      let(:agreed_referee_assignment) { create(:agreed_referee_assignment) }
      before do
        agreed_referee_assignment.report_due_at = 1.second.ago
      end
      it "returns true" do
        expect(agreed_referee_assignment.report_overdue?).to be_true
      end
    end

    context "when the referee has agreed but completed the report, and the due date has not passed" do
      let(:agreed_referee_assignment) { create(:agreed_referee_assignment) }
      it "returns false" do
        expect(agreed_referee_assignment.report_overdue?).to eq(false)
      end
    end

    context "when the referee has agreed and completed the report" do
      let(:completed_referee_assignment) { create(:completed_referee_assignment) }
      it "returns false" do
        expect(completed_referee_assignment.report_overdue?).to eq(false)
      end
    end

    context "when the referee has not agreed" do
      it "returns nil" do
        expect(referee_assignment.report_overdue?).to be_nil
      end
    end
  end

  describe "#visible_to_author?" do
    context "when the report was completed more than 7 days ago" do
      let(:completed_referee_assignment) { create(:completed_referee_assignment) }
      before do
        completed_referee_assignment.update_attributes(report_completed_at: 8.days.ago)
      end
      it "returns true" do
        expect(completed_referee_assignment.visible_to_author?).to be_true
      end
    end

    context "when the report was not completed more than 7 days ago" do
      let(:completed_referee_assignment) { create(:completed_referee_assignment) }
      before do
        completed_referee_assignment.update_attributes(report_completed_at: 6.days.ago)
      end
      it "returns false" do
        expect(completed_referee_assignment.visible_to_author?).to eq(false)
      end
    end
  end

  describe "#agree!" do
    before { referee_assignment.agree! }

    it "sets agreed to true" do
      expect(referee_assignment.agreed).to be_true
    end

    it "sets agreed_at to the present time" do
      expect(referee_assignment.agreed_at).to be_within(1.second).of(Time.current)
    end

    it "saves the above changes" do
      expect(referee_assignment.changed?).to eq(false)
    end
  end

  describe "#decline" do
    before { referee_assignment.decline }

    it "sets agreed to false" do
      expect(referee_assignment.agreed).to eq(false)
    end

    it "sets declined_at to the present time" do
      expect(referee_assignment.declined_at).to be_within(1.second).of(Time.current)
    end

    it "saves the above changes" do
      expect(referee_assignment.changed?).to eq(false)
    end
  end

  describe "#decline_with_comment(comment)" do
    before { referee_assignment.decline_with_comment('Ask someone else') }

    it "sets decline_comment to comment" do
      expect(referee_assignment.decline_comment).to eq('Ask someone else')
    end

    it "sets agreed to false" do
      expect(referee_assignment.agreed).to eq(false)
    end

    it "sets declined_at to the present time" do
      expect(referee_assignment.declined_at).to be_within(1.second).of(Time.current)
    end

    it "saves the above changes" do
      expect(referee_assignment.changed?).to eq(false)
    end
  end

  describe "#declined?" do
    context "when agreed is nil" do
      it "returns false" do
        expect(referee_assignment.declined?).to eq(false)
      end
    end

    context "when agreed is false" do
      before { referee_assignment.agreed = false }
      it "returns true" do
        expect(referee_assignment.declined?).to be_true
      end
    end

    context "when agreed is true" do
      before { referee_assignment.agreed = true }
      it "returns false" do
        expect(referee_assignment.declined?).to eq(false)
      end
    end
  end

  describe "#cancel!" do

    context "when the assignment is not declined" do
      before { referee_assignment.cancel! }

      it "sets canceled to true" do
        expect(referee_assignment.canceled).to be_true
      end

      it "saves the above change" do
        expect(referee_assignment.changed?).to eq(false)
      end

      it "emails the referee" do
        expect(deliveries).to include_email(subject_begins: 'Cancelled Referee Request', to: referee_assignment.referee.email)
        expect(SentEmail.all).to include_record(subject_begins: 'Cancelled Referee Request', to: referee_assignment.referee.email)
      end
    end

    context "when the assignment is declined" do
      before do
        referee_assignment.update_attributes(agreed: false)
        referee_assignment.cancel!
      end

      it "sets canceled to true" do
        expect(referee_assignment.canceled).to be_true
      end

      it "saves the above change" do
        expect(referee_assignment.changed?).to eq(false)
      end

      it "does not email the referee" do
        expect(deliveries).not_to include_email(subject_begins: 'Cancelled Referee Request', to: referee_assignment.referee.email)
        expect(SentEmail.all).not_to include_record(subject_begins: 'Cancelled Referee Request', to: referee_assignment.referee.email)
      end
    end
  end

  describe "#date_assigned_pretty" do
    it "returns assigned_at in Mon. D, YYYY format" do
      referee_assignment.assigned_at = Date.new(2013, 12, 9)
      expect(referee_assignment.date_assigned_pretty).to eq("Dec. 9, 2013")
    end
  end

  describe "#date_agreed_pretty" do
    it "returns agreed_at in Mon. D, YYYY format" do
      referee_assignment.agreed_at = Date.new(2013, 12, 9)
      expect(referee_assignment.date_agreed_pretty).to eq("Dec. 9, 2013")
    end
  end

  describe "#date_declined_pretty" do
    it "returns declined_at in Mon. D, YYYY format" do
      referee_assignment.declined_at = Date.new(2013, 12, 9)
      expect(referee_assignment.date_declined_pretty).to eq("Dec. 9, 2013")
    end
  end

  describe "#date_due_pretty" do
    it "returns report_due_at in Mon. D, YYYY format" do
      referee_assignment.report_due_at = Date.new(2013, 12, 9)
      expect(referee_assignment.date_due_pretty).to eq("Dec. 9, 2013")
    end
  end

  describe "#date_completed_pretty" do
    it "returns report_completed_at in Mon. D, YYYY format" do
      referee_assignment.report_completed_at = Date.new(2013, 12, 9)
      expect(referee_assignment.date_completed_pretty).to eq("Dec. 9, 2013")
    end
  end

  describe "#previous_referee_letter_or_next_available" do

    context "first assignment on a fresh submission" do
      before do
        @submission = create(:submission)
        @assignment = build(:referee_assignment, submission: @submission)
      end

      it "returns 'A'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('A')
      end
    end

    context "second assignment on a fresh submission" do
      before do
        @submission = create(:submission)
        create(:referee_assignment, submission: @submission)
        @assignment = build(:referee_assignment, submission: @submission)
      end

      it "returns 'B'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('B')
      end
    end

    context "third assignment on a fresh submission" do
      before do
        @submission = create(:submission)
        create(:referee_assignment, submission: @submission)
        create(:referee_assignment, submission: @submission)
        @assignment = build(:referee_assignment, submission: @submission)
      end

      it "returns 'C'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('C')
      end
    end

    context "fourth assignment on a first-round submission" do
      before do
        @submission = create(:submission)
        create(:referee_assignment, submission: @submission)
        create(:referee_assignment, submission: @submission)
        create(:referee_assignment, submission: @submission)
        @assignment = build(:referee_assignment, submission: @submission)
      end

      it "returns 'D'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('D')
      end
    end

    context "assignment of same referee from previous round of review" do
      before do
        submission = create(:first_revision_submission)
        previous_assignment = submission.previous_revision
                                        .referee_assignments
                                        .first
        @assignment = build(:referee_assignment, submission: submission, referee: previous_assignment.referee)
      end

      it "returns 'A'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('A')
      end
    end

    context "assignment of a new referee on a second-round of review" do
      before do
        submission = create(:first_revision_submission)
        @assignment = build(:referee_assignment, submission: submission)
      end

      it "returns 'C'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('C')
      end
    end

    context "assignment of another new referee on a second-round of review" do
      before do
        submission = create(:first_revision_submission)
        create(:referee_assignment, submission: submission)
        @assignment = build(:referee_assignment, submission: submission)
      end

      it "returns 'D'" do
        expect(@assignment.send(:previous_referee_letter_or_next_available)).to eq('D')
      end
    end
  end


  # class methods

  describe ".overdue_response_reminder_needed" do

    let!(:referee_assignment) { create(:referee_assignment) }
    let!(:canceled_referee_assignment) { create(:canceled_referee_assignment) }
    let!(:declined_referee_assignment) { create(:declined_referee_assignment) }
    let!(:agreed_referee_assignment) { create(:agreed_referee_assignment) }
    let!(:completed_referee_assignment) { create(:completed_referee_assignment) }

    context "when all referee assignments are new" do
      it "returns no referee assignments" do
        expect(RefereeAssignment.overdue_response_reminder_needed).to be_empty
      end
    end

    context "when one referee assignment has passed response_due_at" do
      before do
        referee_assignment.update_attributes(response_due_at: 1.second.ago)
      end
      it "returns that referee assignment" do
        expect(RefereeAssignment.overdue_response_reminder_needed).to match_array([referee_assignment])
      end
    end

    context "when five referee assignments are passed response_due_at but one is canceled, one declined, one agreed, and one completed" do
      before do
        referee_assignment.update_attributes(response_due_at: 1.second.ago)
        canceled_referee_assignment.update_attributes(response_due_at: 1.second.ago)
        declined_referee_assignment.update_attributes(response_due_at: 1.second.ago)
        agreed_referee_assignment.update_attributes(response_due_at: 1.second.ago)
        completed_referee_assignment.update_attributes(response_due_at: 1.second.ago)
      end
      it "returns the one remaining referee assignment" do
        expect(RefereeAssignment.overdue_response_reminder_needed).to match_array([referee_assignment])
      end
    end

    context "when one referee assignment has passed response_due_at but a reminder has already been sent" do
      before do
        referee_assignment.update_attributes(response_due_at: 1.second.ago)
        NotificationMailer.remind_re_response_overdue(referee_assignment).save_and_deliver
      end
      it "returns no referee assignments" do
        expect(RefereeAssignment.overdue_response_reminder_needed).to be_empty
      end
    end

    context "when one referee assignment has passed response_due_at but its submission is archived" do
      before do
        referee_assignment.update_attributes(response_due_at: 1.second.ago)
        referee_assignment.submission.update_attributes(archived: true)
      end
      it "returns no referee assignments" do
        expect(RefereeAssignment.overdue_response_reminder_needed).to be_empty
      end
    end
  end

  describe ".unanswered_reminder_notification_needed" do
    let!(:referee_assignment) { create(:referee_assignment) }
    let!(:canceled_referee_assignment) { create(:canceled_referee_assignment) }
    let!(:declined_referee_assignment) { create(:declined_referee_assignment) }
    let!(:agreed_referee_assignment) { create(:agreed_referee_assignment) }
    let!(:completed_referee_assignment) { create(:completed_referee_assignment) }

    context "when all assignments are new" do
      it "returns no referee assignments" do
        expect(RefereeAssignment.unanswered_reminder_notification_needed).to be_empty
      end
    end

    context "when one assignment had a response reminder sent #{JournalSettings.days_to_wait_after_invitation_reminder} days ago" do
      before do
        sent_email = NotificationMailer.remind_re_response_overdue(referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)
      end

      it "returns that referee assignment" do
        expect(RefereeAssignment.unanswered_reminder_notification_needed).to match_array([referee_assignment])
      end
    end

    context "when two assignments have had response reminders sent, but only one over #{JournalSettings.days_to_wait_after_invitation_reminder} days ago" do
      before do
        other_referee_assignment = create(:referee_assignment)

        sent_email = NotificationMailer.remind_re_response_overdue(other_referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago + 10.seconds)

        sent_email = NotificationMailer.remind_re_response_overdue(referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)
      end

      it "returns only the second referee assignment" do
        expect(RefereeAssignment.unanswered_reminder_notification_needed).to match_array([referee_assignment])
      end
    end

    context "when two assignments have had response reminders sent, both over #{JournalSettings.days_to_wait_after_invitation_reminder} days ago" do
      before do
        @other_referee_assignment = create(:referee_assignment)

        sent_email = NotificationMailer.remind_re_response_overdue(@other_referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)

        sent_email = NotificationMailer.remind_re_response_overdue(referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)
      end

      it "returns both referee assignments" do
        expect(RefereeAssignment.unanswered_reminder_notification_needed).to match_array([referee_assignment, @other_referee_assignment])
      end
    end

    context "when two assignments have had response reminders sent over #{JournalSettings.days_to_wait_after_invitation_reminder} days ago, but a notification was already sent about one" do
      before do
        @other_referee_assignment = create(:referee_assignment)

        sent_email = NotificationMailer.remind_re_response_overdue(@other_referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)
        sent_email = NotificationMailer.notify_ae_response_reminder_unanswered(@other_referee_assignment).save_and_deliver

        sent_email = NotificationMailer.remind_re_response_overdue(referee_assignment).save_and_deliver
        sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)
      end

      it "returns only the other referee assignment" do
        expect(RefereeAssignment.unanswered_reminder_notification_needed).to match_array([referee_assignment])
      end
    end
  end

  describe ".report_due_soon_reminder_needed" do

    let!(:referee_assignment) { create(:referee_assignment) }
    let!(:canceled_referee_assignment) { create(:canceled_referee_assignment) }
    let!(:declined_referee_assignment) { create(:declined_referee_assignment) }
    let!(:agreed_referee_assignment) { create(:agreed_referee_assignment) }
    let!(:completed_referee_assignment) { create(:completed_referee_assignment) }

    context "when all referee assignments are new" do
      it "returns no referee assignments" do
        expect(RefereeAssignment.report_due_soon_reminder_needed).to be_empty
      end
    end

    context "when one referee assignment is agreed and less than days_before_deadline_to_remind_referee days from report_due_at" do
      before do
        agreed_referee_assignment.update_attributes(report_due_at: (JournalSettings.days_before_deadline_to_remind_referee - 1).days.from_now)
      end
      it "returns that referee assignment" do
        expect(RefereeAssignment.report_due_soon_reminder_needed).to match_array([agreed_referee_assignment])
      end
    end

    context "when one referee assignment is agreed and less than days_before_deadline_to_remind_referee days from report_due_at but a reminder has already been sent" do
      before do
        agreed_referee_assignment.update_attributes(report_due_at: (JournalSettings.days_before_deadline_to_remind_referee - 1).days.from_now)
        NotificationMailer.remind_re_report_due_soon(agreed_referee_assignment).save_and_deliver
      end
      it "returns no referee assignments" do
        expect(RefereeAssignment.report_due_soon_reminder_needed).to be_empty
      end
    end
  end

  describe ".overdue_report" do

    let!(:referee_assignment) { create(:referee_assignment) }
    let!(:canceled_referee_assignment) { create(:canceled_referee_assignment) }
    let!(:declined_referee_assignment) { create(:declined_referee_assignment) }
    let!(:agreed_referee_assignment) { create(:agreed_referee_assignment) }
    let!(:completed_referee_assignment) { create(:completed_referee_assignment) }
    let(:just_long_enough_ago) { (JournalSettings.days_to_remind_overdue_referee.days + 1.second).ago }

    context "when all referee assignments are new" do
      it "returns no referee assignments" do
        expect(RefereeAssignment.overdue_report).to be_empty
      end
    end

    context "when one referee assignment is agreed and report_due_at has passed" do
      before do
        agreed_referee_assignment.update_attributes(report_due_at: just_long_enough_ago)
      end
      it "returns that referee assignment" do
        expect(RefereeAssignment.overdue_report).to match_array([agreed_referee_assignment])
      end
    end

    context "when four referee assignments have passed report_due_at but one is pending, one canceled, one declined, one completed" do
      before do
        referee_assignment.update_attributes(report_due_at: just_long_enough_ago)
        canceled_referee_assignment.update_attributes(report_due_at: just_long_enough_ago)
        declined_referee_assignment.update_attributes(report_due_at: just_long_enough_ago)
        agreed_referee_assignment.update_attributes(report_due_at: just_long_enough_ago)
        completed_referee_assignment.update_attributes(report_due_at: just_long_enough_ago)
      end

      it "returns the one remaining referee assignment" do
        expect(RefereeAssignment.overdue_report).to match_array([agreed_referee_assignment])
      end

      context "when the submission for the pending assignment is withdrawn" do
        before do
          agreed_referee_assignment.submission.withdraw
        end

        it "returns empty" do
          expect(RefereeAssignment.overdue_report).to be_empty
        end
      end
    end
  end


  # modules

  describe RefereeAssignmentReminders do

    describe ".send_overdue_response_reminders" do

      context "when no responses are overdue" do
        before do
          submission = create(:submission_sent_out_for_review)
          RefereeAssignment.send_overdue_response_reminders
        end

        it "sends no reminder emails" do
          expect(deliveries).not_to include_email(subject: 'Reminder to Respond')
          expect(SentEmail.all).not_to include_record(subject: 'Reminder to Respond')
        end
      end

      context "when a response is overdue" do
        before do
          @submission = create(:submission_sent_out_for_review)
          @assignment = @submission.referee_assignments.first
          @assignment.update_attributes(response_due_at: 1.year.ago)
          RefereeAssignment.send_overdue_response_reminders
        end

        it "sends a reminder email" do
          expect(deliveries).to include_email(to: @assignment.referee.email, subject: 'Reminder to Respond', cc: @submission.area_editor.email)
          expect(SentEmail.all).to include_record(to: @assignment.referee.email, subject: 'Reminder to Respond', cc: @submission.area_editor.email)
        end
      end
    end

    describe ".send_unanswered_reminder_notifications" do

      context "when no responses are overdue" do
        before do
          submission = create(:submission_sent_out_for_review)
          RefereeAssignment.send_overdue_response_reminders
        end

        it "sends no reminder emails" do
          expect(deliveries).not_to include_email(subject: 'Referee Request Still Unanswered')
          expect(SentEmail.all).not_to include_record(subject: 'Referee Request Still Unanswered')
        end
      end

      context "when a response is overdue and a reminder was sent over #{JournalSettings.days_to_wait_after_invitation_reminder} days ago" do
        before do
          @submission = create(:submission_sent_out_for_review)
          @assignment = @submission.referee_assignments.first
          @assignment.update_attributes(response_due_at: 1.year.ago)
          sent_email = NotificationMailer.remind_re_response_overdue(@assignment).save_and_deliver
          sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)
          RefereeAssignment.send_unanswered_reminder_notifications
        end

        it "sends a reminder email" do
          expect(deliveries).to include_email(to: @submission.area_editor.email, subject_begins: 'Referee Request Still Unanswered', cc: managing_editor.email)
          expect(SentEmail.all).to include_record(to: @submission.area_editor.email, subject_begins: 'Referee Request Still Unanswered', cc: managing_editor.email)
        end
      end

      context "when two responses are overdue but only one has a reminder that was sent over #{JournalSettings.days_to_wait_after_invitation_reminder} days ago" do
        before do
          @submission1 = create(:submission_sent_out_for_review)
          @assignment1 = @submission1.referee_assignments.first
          @assignment1.update_attributes(response_due_at: 1.year.ago)
          sent_email = NotificationMailer.remind_re_response_overdue(@assignment1).save_and_deliver
          sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago - 1.second)

          @submission2 = create(:submission_sent_out_for_review)
          @assignment2 = @submission2.referee_assignments.first
          @assignment2.update_attributes(response_due_at: 1.year.ago)
          sent_email = NotificationMailer.remind_re_response_overdue(@assignment2).save_and_deliver
          sent_email.update_attributes(created_at: JournalSettings.days_to_wait_after_invitation_reminder.days.ago + 10.seconds)

          RefereeAssignment.send_unanswered_reminder_notifications
        end

        it "sends just one reminder email" do
          expect(deliveries).to include_email(to: @submission1.area_editor.email, subject_begins: 'Referee Request Still Unanswered', cc: managing_editor.email)
          expect(SentEmail.all).to include_record(to: @submission1.area_editor.email, subject_begins: 'Referee Request Still Unanswered', cc: managing_editor.email)

          expect(deliveries).not_to include_email(to: @submission2.area_editor.email, subject_begins: 'Referee Request Still Unanswered', cc: managing_editor.email)
          expect(SentEmail.all).not_to include_record(to: @submission2.area_editor.email, subject_begins: 'Referee Request Still Unanswered', cc: managing_editor.email)
        end
      end
    end

    describe ".send_report_due_soon_reminders" do

      context "when no reports are due soon" do
        before do
          submission = create(:submission_with_two_agreed_referee_assignments)
          RefereeAssignment.send_report_due_soon_reminders
        end

        it "sends no reminder emails" do
          expect(deliveries).not_to include_email(subject_begins: 'Early Reminder')
          expect(SentEmail.all).not_to include_record(subject_begins: 'Early Reminder')
        end
      end

      context "when one report is due soon" do
        before do
          @submission = create(:submission_with_two_agreed_referee_assignments)
          @submission.referee_assignments.each do |assignment|
            @assignment_due_soon = assignment if assignment.agreed? && !assignment.report_completed?
          end
          @assignment_due_soon.update_attributes(report_due_at: 1.minute.from_now)
          RefereeAssignment.send_report_due_soon_reminders
        end

        it "sends a reminder email to that referee" do
          area_editor = @submission.area_editor
          expect(deliveries).to include_email(subject_begins: 'Early Reminder', to: @assignment_due_soon.referee.email, cc: area_editor.email)
          expect(SentEmail.all).to include_record(subject_begins: 'Early Reminder', to: @assignment_due_soon.referee.email, cc: area_editor.email)
        end

        it "doesn't send a reminder to any other referees" do
          referee_to_remind = @assignment_due_soon.referee
          @submission.referees.each do |referee|
            if referee.id != referee_to_remind.id
              expect(deliveries).not_to include_email(subject_begins: 'Early Reminder', to: referee.email)
              expect(SentEmail.all).not_to include_record(subject_begins: 'Early Reminder', to: referee.email)
            end
          end
        end
      end
    end

    describe ".send_overdue_report_reminders" do

      let(:just_long_enough_ago) { (JournalSettings.days_to_remind_overdue_referee.days + 1.second).ago }

      context "when no reports are overdue" do
        before do
          submission = create(:submission_with_two_agreed_referee_assignments)
          RefereeAssignment.send_overdue_report_reminders
        end

        it "sends no reminder emails" do
          expect(deliveries).not_to include_email(subject: 'Overdue Report')
          expect(SentEmail.all).not_to include_record(subject: 'Overdue Report')
        end
      end

      context "when one report is overdue" do
        before do
          @submission = create(:submission_with_two_agreed_referee_assignments)
          active_assignments = @submission.referee_assignments.where(agreed: true, canceled: false)
          @overdue_assignment = active_assignments.first
          @overdue_assignment.update_attributes(report_due_at: just_long_enough_ago)
          @old_deadline = @overdue_assignment.report_due_at
          @other_assignment = active_assignments.last
          RefereeAssignment.send_overdue_report_reminders
        end

        it "sets a new deadline #{JournalSettings.days_to_extend_missed_report_deadlines} days later" do
          @overdue_assignment.reload
          new_deadline = @old_deadline + JournalSettings.days_to_extend_missed_report_deadlines.days
          expect(@overdue_assignment.report_due_at).to be_within_seconds_of(new_deadline)
        end

        it "reminds the referee, notifying them of the new deadline" do
          area_editor = @submission.area_editor
          expect(deliveries).to include_email(subject: 'Overdue Report', to: @overdue_assignment.referee.email, cc: area_editor.email)
          expect(SentEmail.all).to include_record(subject: 'Overdue Report', to: @overdue_assignment.referee.email, cc: area_editor.email)
        end

        it "doesn't do anything with the other referee assignment" do
          @other_assignment.reload
          expect(@other_assignment.report_due_at).to eq(@other_assignment.report_originally_due_at)

          other_referee = @other_assignment.referee
          expect(deliveries).not_to include_email(subject: 'Overdue Report', to: other_referee.email)
          expect(SentEmail.all).not_to include_record(subject: 'Overdue Report', to: other_referee.email)
        end
      end

      context "when two reports are overdue" do
        before do
          submission = create(:submission_with_two_agreed_referee_assignments)
          @overdue_assignment1 = submission.referee_assignments.where(agreed: true, canceled: false, report_completed: false).first
          @overdue_assignment1.update_attributes(report_due_at: just_long_enough_ago)

          submission = create(:submission_with_two_agreed_referee_assignments)
          @overdue_assignment2 = submission.referee_assignments.where(agreed: true, canceled: false, report_completed: false).first
          @overdue_assignment2.update_attributes(report_due_at: just_long_enough_ago)

          @old_deadline = @overdue_assignment1.report_due_at

          RefereeAssignment.send_overdue_report_reminders
        end

        it "sets new deadlines #{JournalSettings.days_to_extend_missed_report_deadlines} days later" do
          @overdue_assignment1.reload
          @overdue_assignment2.reload

          new_deadline = @old_deadline + JournalSettings.days_to_extend_missed_report_deadlines.days

          expect(@overdue_assignment1.report_due_at).to be_within_seconds_of(new_deadline)
          expect(@overdue_assignment2.report_due_at).to be_within_seconds_of(new_deadline)
        end

        it "reminds both referees, notifying them of the new deadlines" do
          area_editor = @overdue_assignment1.submission.area_editor
          expect(deliveries).to include_email(subject: 'Overdue Report', to: @overdue_assignment1.referee.email, cc: area_editor.email)
          expect(SentEmail.all).to include_record(subject: 'Overdue Report', to: @overdue_assignment1.referee.email, cc: area_editor.email)

          area_editor = @overdue_assignment2.submission.area_editor
          expect(deliveries).to include_email(subject: 'Overdue Report', to: @overdue_assignment2.referee.email, cc: area_editor.email)
          expect(SentEmail.all).to include_record(subject: 'Overdue Report', to: @overdue_assignment2.referee.email, cc: area_editor.email)
        end
      end

    end

  end

end
