require 'spec_helper'

describe "Static pages" do 
  describe "Root Page" do
    context "when not logged in" do
      before { visit root_path }
      subject { page }
      it { should have_content('About Ergo') }
    end

    context "when logged in as a managing editor" do
      before do
        valid_sign_in(create(:managing_editor))
        visit root_path
      end

      it "goes to the submissions index" do
        expect(page).to have_link('Archives')
      end
    end

    context "when logged in as an area editor" do
      before do
        valid_sign_in(create(:area_editor))
        visit root_path
      end

      it "goes to the submissions index" do
        expect(page).to have_content('No active submissions')
      end
    end

    context "when logged in as an author/referee" do

      context "with an active referee assignment" do
        before do
          create(:managing_editor)
          referee = create(:referee)
          create(:submission_sent_out_for_review).referee_assignments.first.update_attributes(referee: referee)
          valid_sign_in(referee)
          visit root_path
        end

        it "goes to the submissions index" do
          expect(page).to have_content('Invited')
        end
      end

      context "with no active referee assignment" do
        before do
          valid_sign_in(create(:user))
          visit root_path
        end

        it "goes to the submissions index" do
          expect(page).to have_link('Submit a paper')
        end
      end
    end
  end

  describe "Guide Page" do
    context "when logged in as an area editor" do
      before do
        valid_sign_in(create(:area_editor))
        visit guide_path
      end
      
      it "has a link to the guide" do
        expect(page).to have_link('guide', href: guide_path)
      end
      
      it "displays the guide page" do
        expect(page).to have_content('Editor\'s Guide')
      end
    end
    
    context "when logged in as an author" do
      before do
        valid_sign_in(create(:author))
      end
      
      it "doesn't link to the guide" do
        expect(page).not_to have_link('guide', href: guide_path)
      end
      
      it "blocks access to the guide" do
        visit guide_path
        expect(current_path).to eq(security_breach_path)
      end
    end
  end

  describe "About Page" do
    before { visit about_path }
    subject { page }
    it { should have_content('About') }
  end

  describe "Peer Review Page" do
    before { visit peer_review_path }
    subject { page }
    it { should have_content('Peer Review') }
  end

  describe "Contact Page" do
    before { visit contact_path }
    subject { page }
    it { should have_content('Contact') }
  end
end