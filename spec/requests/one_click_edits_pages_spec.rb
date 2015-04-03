require 'spec_helper'

describe "One-click edits pages" do
  
  let!(:managing_editor) { create(:managing_editor) }
  let(:submission) { create(:submission_assigned_to_area_editor) }
  
  context "when supplied the auth_token of some submission" do
    before { visit one_click_edit_path(submission.auth_token) }
  
    it "redirects to that submission's show page" do
      expect(current_path).to eq(submission_path(submission))
      expect(page).to have_content(submission.title)
    end
    
    it "signs us in as that submission's area_editor" do
      expect(page).to have_content(submission.area_editor.full_name)
    end
  end
  
  context "when supplied with an invalid auth_token" do
    before { visit one_click_edit_path("abcd1234") }
  
    it "redirects to security breach" do
      expect(current_path).to eq(security_breach_path)
    end
    
    it "does not sign us in as that submission's area editor" do
      expect(page).not_to have_content(submission.area_editor.full_name)
    end
  end
end