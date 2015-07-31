require 'spec_helper'

describe NotificationMailerHelper do
  let!(:managing_editor) { create(:managing_editor) }
  let(:desk_rejected_submission) { create(:desk_rejected_submission) }
  let(:major_revisions_requested_submission) { create(:major_revisions_requested_submission) }
  let(:referee_assignment) { create(:completed_referee_assignment) }
  subject { submission }  

  describe "#humanize" do
    it "returns english words for numbers between 0 and 10; numeral strings otherwise" do
      expect(humanize(-1)).to eq('-1')
      expect(humanize(0)).to eq 'zero'
      expect(humanize(3)).to eq 'three'
      expect(humanize(10)).to eq 'ten'
      expect(humanize(11)).to eq '11'
    end
    
    it "capitalizes as instructed" do
      expect(humanize(-1, capitalize: true)).to eq('-1')
      expect(humanize(0, capitalize: true)).to eq 'Zero'
      expect(humanize(3, capitalize: true)).to eq 'Three'
      expect(humanize(10, capitalize: true)).to eq 'Ten'
      expect(humanize(11, capitalize: true)).to eq '11'
    end
  end

  describe "#report_for_area_editor" do
    it "returns the recommendation and all comments as a string" do
      expect(report_for_area_editor(referee_assignment)).to match(/^Recommendation: Major Revisions/)
      expect(report_for_area_editor(referee_assignment)).to match(/^Comments for the Editor: see attached file./)
      expect(report_for_area_editor(referee_assignment)).to match(/^Lorem ipsum dolor sit amet/)
      expect(report_for_area_editor(referee_assignment)).to match(/^Comments for the Author: see attached file./)
      expect(report_for_area_editor(referee_assignment)).to match(/Excepteur sint occaecat cupidatat/)
    end
  end

  describe "#report_for_author" do
    it "returns the recommendation and the comments for the author only" do
      expect(report_for_author(referee_assignment)).to match(/^Recommendation: Major Revisions/)
      expect(report_for_author(referee_assignment)).not_to match(/^Comments for the Editor: see attached file./)
      expect(report_for_author(referee_assignment)).to match(/^Comments for the Author: see attached file./)
      expect(report_for_author(referee_assignment)).to match(/Excepteur sint occaecat cupidatat/)
    end
  end

  describe "#all_comments_for_author" do
    it "returns all feedback for the author as a string" do
      
      # Desk rejection
      expect(all_comments_for_author(desk_rejected_submission)).to match(/^Comments from the Area Editor/)
      expect(all_comments_for_author(desk_rejected_submission)).to match(/^-----------------------------/)
      expect(all_comments_for_author(desk_rejected_submission)).to match(/^Lorem ipsum dolor sit amet/)

      expect(all_comments_for_author(desk_rejected_submission)).not_to match(/^Referee/)
      expect(all_comments_for_author(desk_rejected_submission)).not_to match(/^Comments for the Author/)
      expect(all_comments_for_author(desk_rejected_submission)).not_to match(/^Comments for the Editor/)      

      # Major Revisions requested
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^Comments from the Area Editor/)
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^-----------------------------$/)
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^Lorem ipsum dolor sit amet/)

      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^Referee A/)
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^---------$/)
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^Recommendation: Major Revisions/)
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^Comments for the Author: see attached file./)
      expect(all_comments_for_author(major_revisions_requested_submission)).to match(/^Referee B/)
      expect(all_comments_for_author(major_revisions_requested_submission)).not_to match(/^Comments for the Editor/)

    end
  end
end