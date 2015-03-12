require 'spec_helper'

describe JournalSettings do
  
  let(:journal_settings) { FactoryGirl.build(:journal_settings) }
  subject { journal_settings }
  
  
  # attributes
  
  shared_examples_for "a journal_settings instance" do  
    it { should respond_to(:days_for_initial_review) }
    it { should respond_to(:days_to_respond_to_referee_request) }
    it { should respond_to(:days_to_assign_area_editor) }
    it { should respond_to(:days_to_remind_unanswered_invitation) }
    it { should respond_to(:days_for_external_review) }
    it { should respond_to(:days_to_remind_area_editor) }
    it { should respond_to(:days_to_assign_area_editor) }
    it { should respond_to(:days_before_deadline_to_remind_referee) }
    it { should respond_to(:number_of_reports_expected) }
    it { should respond_to(:days_to_remind_overdue_decision_approval) }
    it { should respond_to(:days_after_reports_completed_to_submit_decision) }
    it { should respond_to(:journal_email) }    
  end
  
  describe "JournalSettings instance" do
    it_behaves_like "a journal_settings instance"
    it { should be_valid }
  end   
  

  # defaults
   it "sets default values" do
    expect(JournalSettings.days_to_assign_area_editor).to eq(2)
    expect(JournalSettings.days_for_initial_review).to eq(14)
    expect(JournalSettings.days_to_remind_area_editor).to eq(3)
    expect(JournalSettings.days_for_external_review).to eq(28)
    expect(JournalSettings.days_to_respond_to_referee_request).to eq(3)
    expect(JournalSettings.days_to_remind_unanswered_invitation).to eq(1)
    expect(JournalSettings.days_to_remind_overdue_referee).to eq(1)
    expect(JournalSettings.days_before_deadline_to_remind_referee).to eq(7)
    expect(JournalSettings.days_after_reports_completed_to_submit_decision).to eq(5)
    expect(JournalSettings.days_to_remind_overdue_decision_approval).to eq(1)
    expect(JournalSettings.number_of_reports_expected).to eq(2)
    expect(JournalSettings.journal_email).to eq("ergo.editors@gmail.com")
  end
  
  # validations
  
  it "is not valid unless days_for_initial_review is between 0 and 1000" do
    journal_settings.days_for_initial_review = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_for_initial_review = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_to_respond_to_referee_request is between 0 and 1000" do
    journal_settings.days_to_respond_to_referee_request = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_to_respond_to_referee_request = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_to_assign_area_editor is between 0 and 1000" do
    journal_settings.days_to_assign_area_editor = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_to_assign_area_editor = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_to_remind_unanswered_invitation is between 0 and 1000" do
    journal_settings.days_to_remind_unanswered_invitation = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_to_remind_unanswered_invitation = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_for_external_review is between 0 and 1000" do
    journal_settings.days_for_external_review = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_for_external_review = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_for_external_review is between 0 and 1000" do
    journal_settings.days_for_external_review = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_for_external_review = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_to_remind_area_editor is between 0 and 1000" do
    journal_settings.days_to_remind_area_editor = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_to_remind_area_editor = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_to_assign_area_editor is between 0 and 1000" do
    journal_settings.days_to_assign_area_editor = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_to_assign_area_editor = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_before_deadline_to_remind_referee is between 0 and 1000" do
    journal_settings.days_before_deadline_to_remind_referee = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_before_deadline_to_remind_referee = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless number_of_reports_expected is between 0 and 1000" do
    journal_settings.number_of_reports_expected = -1
    expect(journal_settings).not_to be_valid
    journal_settings.number_of_reports_expected = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_to_remind_overdue_decision_approval is between 0 and 1000" do
    journal_settings.days_to_remind_overdue_decision_approval = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_to_remind_overdue_decision_approval = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid unless days_after_reports_completed_to_submit_decision is between 0 and 1000" do
    journal_settings.days_after_reports_completed_to_submit_decision = -1
    expect(journal_settings).not_to be_valid
    journal_settings.days_after_reports_completed_to_submit_decision = 1001
    expect(journal_settings).not_to be_valid
  end
  
  it "is not valid when journal_email is the wrong format" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com]
    addresses.each do |invalid_address|
      journal_settings.journal_email = invalid_address
      expect(journal_settings).not_to be_valid
    end
  end
  
  it "is not valid when days_for_external_review is less than days_before_deadline_to_remind_referee" do
    journal_settings.days_for_external_review = 6
    journal_settings.days_before_deadline_to_remind_referee = 7
    expect(journal_settings).not_to be_valid
  end


  # class methods
  
  describe "JournalSettings has a class method corresponding to each instance attribute" do
    subject { JournalSettings }
    it_behaves_like "a journal_settings instance"
  end
  
  
  # instance methods
  
  describe "#current" do
    it "returns a JournalSettings object" do
      expect(JournalSettings.current).to be_an_instance_of(JournalSettings)
    end
  end

  
end
