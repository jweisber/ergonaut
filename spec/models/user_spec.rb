# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_digest        :string(255)
#  remember_token         :string(255)
#  managing_editor        :boolean
#  area_editor            :boolean
#  author                 :boolean
#  referee                :boolean
#  first_name             :string(255)
#  middle_name            :string(255)
#  last_name              :string(255)
#  affiliation            :string(255)
#  password_reset_token   :string(255)
#  password_reset_sent_at :datetime
#

require 'spec_helper'

describe User do
  let(:user) { build(:user) }  
  subject { user }


  # valid factory
  
  it { should be_valid }
  
  
  # attributes
    
  it { should respond_to(:first_name) }
  it { should respond_to(:middle_name) }
  it { should respond_to(:last_name) }
  it { should respond_to(:email) }
  it { should respond_to(:password) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:managing_editor) }
  it { should respond_to(:area_editor) }
  it { should respond_to(:author) }
  it { should respond_to(:referee) }
  it { should respond_to(:affiliation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:password_reset_token) }
  it { should respond_to(:password_reset_sent_at) }
  it { should respond_to(:authenticate) }
  
  
  # autos & defaults
  
  its(:remember_token) { should_not be_blank }
  its(:managing_editor) { should eq(false) }
  its(:area_editor) { should eq(false) }
  its(:referee) { should be_true }
  its(:author) { should be_true }
  
  
  # validations
  
  describe "when first name is empty" do
    before { user.first_name = "" }
    it { should_not be_valid }
  end
  
  describe "when first name is too long" do
    before { user.first_name = "a" * 51 }
    it { should_not be_valid }
  end
  
  describe "when middle name is empty" do
    before { user.middle_name = "" }
    it { should be_valid }
  end
  
  describe "when middle name is too long" do
    before { user.middle_name = "a" * 51 }
    it { should_not be_valid }
  end
  
  describe "when last name is empty" do
    before { user.last_name = "" }
    it { should_not be_valid }
  end
  
  describe "when last name is too long" do
    before { user.last_name = "a" * 51 }
    it { should_not be_valid }
  end
  
  describe "when email is empty" do
    before { user.email = "" }
    it { should_not be_valid }
  end
  
  describe "when email is wrong format" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com]
      addresses.each do |invalid_address|
        user.email = invalid_address
        expect(user).not_to be_valid
      end
    end
  end
  
  describe "when email is right format" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        user.email = valid_address
        expect(user).to be_valid
      end
    end
  end
  
  describe "when email is already taken" do
    it "should be invalid" do
      user.save
      user_with_same_email = user.dup
      user_with_same_email.email = user_with_same_email.email.upcase
      user_with_same_email.save
      expect(user_with_same_email).not_to be_valid
    end
  end
  
  describe "when password is not present" do
    before do
      user.password = ""
    end
    it { should_not be_valid }
  end
  
  describe "when password is too short" do
    before { user.password = user.password_confirmation = "a" * 5 }
    it { should be_invalid }
  end
  
  describe "when password doesn't match confirmation" do
    before do
      user.password_confirmation = "mismatch"
    end
    it { should_not be_valid }
  end
  
  
  # class methods
  
  describe ".find_by_fuzzy_full_name_affiliation_email" do
    let(:joe_user) { create(:user, first_name: 'Joe', last_name: 'Schmo', email: 'biz@baz.com') }
    before do
      joe_user
      1.times { create(:managing_editor) }
      2.times { create(:area_editor) }
      3.times { create(:user) }  
    end
    
    it "returns users with fuzzily matching names" do
      expect(User.find_by_fuzzy_full_name_affiliation_email('Jo Shmo')).to include(joe_user)
    end
    
    it "returns users with fuzzily matching emails" do
      expect(User.find_by_fuzzy_full_name_affiliation_email('biz@bax')).to include(joe_user)
    end
  end
  
  describe ".roles" do
    it "should be ['Managing editor', 'Area editor', 'Author/referee']" do
      expect(User.roles).to eq(['Managing editor', 'Area editor', 'Author/referee'])
    end
  end
  
  describe ".area_editor_histories_table" do
    it "returns HTML summary of area editors' assignments" do
      expect(User.area_editor_histories_table).not_to be_blank
    end
  end
  
  describe ".area_editors_ordered_by_last_name" do
    let!(:managing_editor1) { create(:managing_editor) }
    let!(:area_editor1) { create(:area_editor, last_name: 'Albatross') }
    let!(:user1) { create(:user) }
    let!(:managing_editor2) { create(:managing_editor) }
    let!(:user2) { create(:user) }
    let!(:area_editor2) { create(:area_editor, last_name: 'Canary') }    
    let!(:area_editor3) { create(:area_editor, last_name: 'Bluejay') }
    let!(:user3) { create(:user) }
    let!(:managing_editor3) { create(:managing_editor) }
    
    it "returns all area editors in order by last name" do
      expect(User.area_editors_ordered_by_last_name[0]).to eq(area_editor1)
      expect(User.area_editors_ordered_by_last_name[1]).to eq(area_editor3)
      expect(User.area_editors_ordered_by_last_name[2]).to eq(area_editor2)
      expect(User.area_editors_ordered_by_last_name.count).to eq(3)
    end
    
  end
 
  describe ".referees_ordered_by_last_name" do
    let!(:managing_editor1) { create(:managing_editor) }
    let!(:area_editor1) { create(:area_editor) }
    let!(:user1) { create(:user, last_name: 'Bluejay') }
    let!(:managing_editor2) { create(:managing_editor) }
    let!(:user2) { create(:user, last_name: 'Albatross') }
    let!(:area_editor2) { create(:area_editor) }    
    let!(:area_editor3) { create(:area_editor) }
    let!(:user3) { create(:user, last_name: 'Canary') }
    let!(:managing_editor3) { create(:managing_editor) }
    
    it "returns all referees in order by last name" do
      expect(User.referees_ordered_by_last_name[0]).to eq(user2)
      expect(User.referees_ordered_by_last_name[1]).to eq(user1)
      expect(User.referees_ordered_by_last_name[2]).to eq(user3)
      expect(User.referees_ordered_by_last_name.count).to eq(3)
    end
  end
  
  describe ".map_area_editor_ids_to_completed_assignment_counts" do
    
    let(:area_editor1) { create(:area_editor) }
    let(:area_editor2) { create(:area_editor) }
    let(:area_editor3) { create(:area_editor) }
    
    before(:each) do
      create(:managing_editor)      
      create(:submission)
      
      create(:submission_assigned_to_area_editor, area_editor: area_editor1)
      create(:submission_sent_out_for_review, area_editor: area_editor1)
      create(:submission_with_two_agreed_referee_assignments, area_editor: area_editor1)
      create(:desk_rejected_submission, area_editor: area_editor1)
      create(:submission_with_two_completed_referee_assignments, area_editor: area_editor1)
      create(:major_revisions_requested_submission, area_editor: area_editor1)
      create(:minor_revisions_requested_submission, area_editor: area_editor1)
      create(:accepted_submission, area_editor: area_editor1)
      
      create(:desk_rejected_submission, area_editor: area_editor2)
      create(:major_revisions_requested_submission, area_editor: area_editor2)
      create(:minor_revisions_requested_submission, area_editor: area_editor2)
      create(:accepted_submission, area_editor: area_editor2)
      
      area_editor3
    end
    
    it "returns a hash mapping each area editor's id to the number of assignments they've completed" do
      hash = User.map_area_editor_ids_to_completed_assignment_counts
      expect(hash[area_editor1.id]).to eq(4)
      expect(hash[area_editor2.id]).to eq(4)
    end
    
    it "doesn't include area editors with no completed assignments" do
      hash = User.map_area_editor_ids_to_completed_assignment_counts
      expect(hash[area_editor3.id]).to be_nil
    end
  end
  
  describe ".map_area_editor_ids_to_active_assignments_counts" do
    
    let(:area_editor1) { create(:area_editor) }
    let(:area_editor2) { create(:area_editor) }
    let(:area_editor3) { create(:area_editor) }
    
    before(:each) do
      create(:managing_editor)
      create(:submission)
      
      create(:submission_assigned_to_area_editor, area_editor: area_editor1)
      create(:submission_sent_out_for_review, area_editor: area_editor1)
      create(:submission_with_two_agreed_referee_assignments, area_editor: area_editor1)
      create(:desk_rejected_submission, area_editor: area_editor1)
      create(:submission_with_two_completed_referee_assignments, area_editor: area_editor1)
      create(:major_revisions_requested_submission, area_editor: area_editor1)
      create(:minor_revisions_requested_submission, area_editor: area_editor1)
      create(:accepted_submission, area_editor: area_editor1)
      
      create(:submission_assigned_to_area_editor, area_editor: area_editor2)
      create(:submission_sent_out_for_review, area_editor: area_editor2)
      
      area_editor3
    end
    
    it "returns a hash mapping each area editor's id to the number of assignments they've completed" do
      hash = User.map_area_editor_ids_to_active_assignments_counts
      expect(hash[area_editor1.id]).to eq(4)
      expect(hash[area_editor2.id]).to eq(2)
    end
    
    it "doesn't include area editors with no completed assignments" do
      hash = User.map_area_editor_ids_to_active_assignments_counts
      expect(hash[area_editor3.id]).to be_nil
    end
  end


  # instance methods
    
  describe "#role=" do
    
    context "when assigned 'Managing editor'" do
      before(:each) { user.role = 'Managing editor' }
      it "makes managing_editor true and the other three booleans false" do
        expect(user.managing_editor).to be_true
        expect(user.area_editor).to eq(false)
        expect(user.author).to eq(false)
        expect(user.referee).to eq(false)
      end   
    end
    
    context "when assigned 'Area editor'" do
      before(:each) { user.role = 'Area editor' }
      it "makes area_editor true and the other three booleans false" do
        expect(user.managing_editor).to eq(false)
        expect(user.area_editor).to be_true
        expect(user.author).to eq(false)
        expect(user.referee).to eq(false)
      end   
    end
    
    context "when assigned 'Author/referee'" do
      before(:each) { user.role = 'Author/referee' }
      it "makes author and referee true, the other two booleans false" do
        expect(user.managing_editor).to eq(false)
        expect(user.area_editor).to eq(false)
        expect(user.author).to be_true
        expect(user.referee).to be_true
      end   
    end
        
  end
  
  describe "#role" do
    its(:role) { should satisfy { |r| User.roles.include?(r) } }
  end
  
  describe "#editor?" do
    
    context "when managing_editor and area_editor are false" do
      before(:each) { user.managing_editor = user.area_editor = false }
      it "returns false" do
        expect(user.editor?).to eq(false)
      end
    end
    
    context "when managing_editor is true" do
      before(:each) { user.managing_editor = true }
      it "returns true" do
        expect(user.editor?).to be_true
      end
    end
    
    context "when area_editor is true" do
      before(:each) { user.area_editor = true }
      it "returns true" do
        expect(user.editor?).to be_true
      end
    end
    
  end
  
  describe "#active_referee_assignments" do
    before { create(:managing_editor) }
    let(:user) { create(:user) }
    let!(:referee_assignment) { create(:referee_assignment, referee: user) }    
    let!(:canceled_referee_assignment) { create(:canceled_referee_assignment, referee: user) }
    let!(:declined_referee_assignment) { create(:declined_referee_assignment, referee: user) }
    let!(:agreed_referee_assignment) { create(:agreed_referee_assignment, referee: user) }        
    let!(:completed_referee_assignment) { create(:completed_referee_assignment, referee: user) }
    
    it "returns assignments that are unanswered, uncompleted, and undeclined" do
      expect(user.active_referee_assignments).to include(referee_assignment)
      expect(user.active_referee_assignments).to include(agreed_referee_assignment)
    end    
        
    it "doesn't return canceled assignments" do
      expect(user.active_referee_assignments).not_to include(canceled_referee_assignment)
    end
    
    it "doesn't return declined assignments" do
      expect(user.active_referee_assignments).not_to include(declined_referee_assignment)
    end
    
    it "doesn't return completed assignments" do
      expect(user.active_referee_assignments).not_to include(completed_referee_assignment)
    end
  end
  
  describe "#inactive_referee_assignments" do
    before { create(:managing_editor) }
    let(:user) { create(:user) }
    let!(:referee_assignment) { create(:referee_assignment, referee: user) }    
    let!(:canceled_referee_assignment) { create(:canceled_referee_assignment, referee: user) }
    let!(:declined_referee_assignment) { create(:declined_referee_assignment, referee: user) }
    let!(:agreed_referee_assignment) { create(:agreed_referee_assignment, referee: user) }        
    let!(:completed_referee_assignment) { create(:completed_referee_assignment, referee: user) }
        
    it "returns canceled assignments" do
      expect(user.inactive_referee_assignments).to include(canceled_referee_assignment)
    end
    
    it "returns declined assignments" do
      expect(user.inactive_referee_assignments).to include(declined_referee_assignment)
    end
    
    it "returns completed assignments" do
      expect(user.inactive_referee_assignments).to include(completed_referee_assignment)
    end
    
    it "doesn't return assignments that are unanswered, uncompleted, and undeclined" do
      expect(user.inactive_referee_assignments).not_to include(referee_assignment)
      expect(user.inactive_referee_assignments).not_to include(agreed_referee_assignment)
    end
  end
  
  describe "#active_submissions" do
    before { create(:managing_editor) }
    let(:user) { create(:user) }
    let!(:submission) { create(:submission, author: user) }
    let!(:desk_rejected_submission) { create(:desk_rejected_submission, author: user) }
    let!(:major_revisions_requested_submission) { create(:major_revisions_requested_submission, author: user) }
    
    it "returns non-archived submissions" do
      expect(user.active_submissions).to include(submission)
    end
    
    it "returns archived submissions if they need revisions" do
      expect(user.active_submissions).to include(major_revisions_requested_submission)
    end
    
    it "doesn't return archived submissions otherwise" do
      expect(user.active_submissions).not_to include(desk_rejected_submission)
    end

  end
  
  describe "#inactive_submissions" do
    before { create(:managing_editor) }    
    let!(:user) { create(:user) }
    let!(:fresh_submission) { create(:submission, author: user) }
    let!(:desk_rejected_submission) { create(:desk_rejected_submission, author: user) }
    let!(:major_revisions_requested_submission) { create(:major_revisions_requested_submission, author: user) }
    let!(:accepted_submission) { create(:accepted_submission, author: user) }
    
    it "returns submissions that were withdrawn or decided, unless awaiting R&R." do
      expect(user.inactive_submissions).to include(desk_rejected_submission)
      expect(user.inactive_submissions).to include(accepted_submission)
      expect(user.inactive_submissions).not_to include(fresh_submission)
      expect(user.inactive_submissions).not_to include(major_revisions_requested_submission)
    end
  end
  
  describe "#has_pending_referee_assignments?" do
    before { create(:managing_editor) }
    let(:referee) { create(:referee) }
    subject { referee.has_pending_referee_assignments? }
    
    context "when there is a fresh referee assignment" do
      before { create(:referee_assignment, referee: referee, submission: create(:submission)) }
      it { should be_true}
    end
    
    context "when there is only a canceled referee assignment" do
      before { create(:canceled_referee_assignment, referee: referee, submission: create(:submission)) }
      it { should eq(false)}
    end
    
    context "when there is only a declined referee assignment" do
      before { create(:declined_referee_assignment, referee: referee, submission: create(:submission)) }
      it { should eq(false)}
    end
    
    context "when there is an agreed but not completed referee assignment" do
      before { create(:agreed_referee_assignment, referee: referee, submission: create(:submission)) }
      it { should be_true}
    end
    
    context "when there is only a completed referee assignment" do
      before { create(:completed_referee_assignment, referee: referee, submission: create(:submission)) }
      it { should eq(false)}
    end
    
    context "when there are only canceled, declined, and completed referee assignments" do
      before do
        create(:canceled_referee_assignment, referee: referee, submission: create(:submission))
        create(:declined_referee_assignment, referee: referee, submission: create(:submission))
        create(:completed_referee_assignment, referee: referee, submission: create(:submission))
      end
      
      it { should eq(false)}
    end
    
    context "when there are fresh, canceled, declined, agreed, and completed referee assignments" do
      before do
        create(:referee_assignment, referee: referee, submission: create(:submission))
        create(:canceled_referee_assignment, referee: referee, submission: create(:submission))
        create(:declined_referee_assignment, referee: referee, submission: create(:submission))
        create(:agreed_referee_assignment, referee: referee, submission: create(:submission))
        create(:completed_referee_assignment, referee: referee, submission: create(:submission))
      end
      
      it { should be_true}
    end
    
  end
  
  describe "#full_name" do
    let(:user) { create(:user, first_name: 'Foo', middle_name: 'F.', last_name: 'Bar') }
    subject { user.full_name }
    
    context "when user has a middle name" do
      it { should eq('Foo F. Bar')}
    end
    
    context "when user doesn't have a middle name" do
      before { user.middle_name = nil }
      it { should eq('Foo Bar')}
    end
  end
  
  describe "#full_name_brackets_email" do
    let(:user) { create(:user, first_name: 'Foo', middle_name: 'F.', last_name: 'Bar', affiliation: 'University of Fubar', email: 'foobar@example.com') }
    subject{ user.full_name_brackets_email }
    
    context "when user has a middle name" do
      it { should eq('Foo F. Bar <foobar@example.com>')}
    end
    
    context "when user doesn't have a middle name" do
      before { user.middle_name = nil }
      it { should eq('Foo Bar <foobar@example.com>')}
    end
  end
  
  describe "#full_name_affiliation_email" do
    let(:user) { create(:user, first_name: 'Foo', middle_name: 'F.', last_name: 'Bar', affiliation: 'University of Fubar', email: 'foobar@example.com') }
    subject{ user.full_name_affiliation_email }
    
    context "when user has a middle name" do
      it { should eq('Foo F. Bar (University of Fubar, foobar@example.com)')}
    end
    
    context "when user doesn't have a middle name" do
      before { user.middle_name = nil }
      it { should eq('Foo Bar (University of Fubar, foobar@example.com)')}
    end
  end

  describe "#create_another_user" do
    let(:params) { ActionController::Parameters.new({ first_name: 'Foo', middle_name: 'F.', last_name: 'Bar', affiliation: 'University of Fooville', email: 'foo.bar@example.com', password: 'secret', password_confirmation: 'secret', role: 'Managing editor' }) }
    let(:created_user) { creator.create_another_user(params) }
  
    context "when created by an area editor" do 
      let(:creator) { create(:area_editor) }
      
      it "assigns a random password" do
        expect(created_user.authenticate('secret')).not_to be_true
        expect(created_user.password_digest).not_to be_blank
      end
      
      it "creates an Author/referee" do
        expect(created_user.role).to eq('Author/referee')
      end
      
      it "emails the created user a notification" do
        expect(NotificationMailer).to receive(:notify_creator_registration).and_call_original
        created_user        
      end
    end
    
    context "when created by a managing editor" do
      let (:creator) { create(:managing_editor) }
      
      it "can assign a password" do
        expect(created_user.authenticate('secret')).to be_true
      end
      
      it "can create an Editor" do
        expect(created_user.managing_editor).to be_true
      end
      
      it "emails the created user a notification" do
        expect(NotificationMailer).to receive(:notify_creator_registration).and_call_original
        created_user      
      end
    end    
    
  end
  
  describe "#permitted_params(params)" do
    let(:managing_editor) { create(:managing_editor) }
    let(:area_editor) { create(:area_editor) }
    let(:user) { create(:user) }
    let(:params) { ActionController::Parameters.new({ first_name: 'Foo', middle_name: 'F.', last_name: 'Bar', affiliation: 'University of Fooville', email: 'foo.bar@example.com', password: 'secret', password_confirmation: 'secret', role: 'Managing editor' }) }

    context "when user is a managing editor" do
      it "permits all parameters" do
        permitted = managing_editor.permitted_params(params)
        expect(permitted.keys).to eq(params.keys)
      end
    end
    
    context "when user is an area editor" do
      it "permits all parameters" do
        permitted = area_editor.permitted_params(params)
        expect(permitted.keys).to include('first_name', 'middle_name', 'last_name', 'affiliation', 'email')
      end
    end
    
    context "when user is not an editor" do
      it "permits all parameters" do
        permitted = user.permitted_params(params)
        expect(permitted.keys).to be_empty
      end
    end
    
  end
  
  describe "#authenticate" do
    before(:each) { user.save }
    let(:found_user) { User.find_by_email(user.email)  }
    
    context "with valid password" do
      it { should eq found_user.authenticate(user.password) }
    end
    
    context "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }
      it { should_not eq user_for_invalid_password }
      specify { expect(user_for_invalid_password).to eq(false) }
    end
  end
  
  describe "#new_password_reset_token" do
    
    before(:each) { user.new_password_reset_token }
    
    it "changes password_reset_token" do
      expect(user.password_reset_token).not_to eq(user.password_reset_token_was)
    end
    
    it "creates a non-empty password_reset_token" do
      expect(user.password_reset_token).not_to be_blank
    end
    
    it "creates a unique password_reset_token" do
      conflicting_user = User.find_by_password_reset_token(user.password_reset_token)
      expect(conflicting_user).to be_nil
    end
    
  end
  
  describe "#send_password_reset" do
    
    before(:each) do
      user.save
      user.send_password_reset
    end

    it "creates new password_reset_token" do
      user.password_reset_token_changed?
    end
    
    it "saves new password_reset_token" do
      found_user = User.find_by_password_reset_token(user.password_reset_token)
      expect(user).to eq(found_user)
    end
    
    it "emails reset link to user" do
      expect(NotificationMailer).to receive(:notify_password_reset).and_call_original
      user.send_password_reset # needs to happen after the should_receive call, o.w. redundant with the before block
    end
    
  end
    
end
