require 'spec_helper'

describe AreaEditorAssignment do
  
  let!(:managing_editor) { create(:managing_editor) }
  let(:area_editor_assignment) { build(:area_editor_assignment) }  
  subject{ area_editor_assignment }
  

  # valid factory
  
  it { should be_valid }
  
  
  # callback behaviours
  
  describe "after saving" do
    context "when the assignment is new" do
      it "emails the new area editor" do
        expect(NotificationMailer).to receive(:notify_ae_new_assignment).and_call_original
        area_editor_assignment.save
      end
    end
    
    context "when the assignment is changing hands" do
      before do
        area_editor_assignment.save
        @old_auth_token = area_editor_assignment.submission.auth_token
        area_editor_assignment.area_editor = create(:area_editor)
      end
      
      it "changes the submission's auth_token" do
        area_editor_assignment.save
        expect(area_editor_assignment.submission.auth_token).not_to eq(@old_auth_token)
      end
      
      it "Emails both the old area editor and the new one" do
        expect(NotificationMailer).to receive(:notify_ae_assignment_canceled).and_call_original
        expect(NotificationMailer).to receive(:notify_ae_new_assignment).and_call_original
        area_editor_assignment.save
      end
    end
  end
  
  describe "after destroying", working: true do
    it "sets a new auth_token in the corresponding submission" do
      area_editor_assignment.save
      submission = area_editor_assignment.submission
      old_auth_token = submission.auth_token
      area_editor_assignment.destroy      
      expect(submission.auth_token).not_to eq(old_auth_token)
    end
    
    it "saves the change to the submission" do
      area_editor_assignment.save
      submission = area_editor_assignment.submission
      area_editor_assignment.destroy      
      expect(submission.changed?).to eq(false)
    end
    
    it "emails the area editor" do
      area_editor_assignment.save
      expect(NotificationMailer).to receive(:notify_ae_assignment_canceled).and_call_original
      area_editor_assignment.destroy
    end
  end
end
