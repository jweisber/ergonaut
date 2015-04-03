require 'spec_helper'

describe "Authentication" do
  
  subject { page }
  
  describe "signin page" do
    before { visit signin_path }
    
    it { should have_content('Sign in') }
  end
  
  describe "signin" do
    before { visit signin_path }
    
    describe "with invalid information" do
      before { click_button 'Sign in' }
      
      it { should have_content('Sign in') }
      it { should have_error_message('Invalid') }
      
      describe "after visiting another page" do
        before { visit root_path }
        it { should_not have_error_message('') }
      end
    end
    
    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      before  { valid_sign_in(user) }
      
      it { should have_link('Profile',      href: user_path(user)) }
      it { should have_link('Sign out',     href: signout_path) }
      it { should_not have_button('Sign in') }
      
      describe "followed by signout" do
        before { click_link 'Sign out' }
        it { should have_button('Sign in') }
      end
    end
    
  end
  
  describe "authorization" do
    
    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      
      describe "in the Users controller" do
        
        describe "visiting the index page" do
          before { visit users_path }
          it { should have_selector('legend', text: 'Sign in') }
        end
        
        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_selector('legend', text: 'Sign in') }
        end
        
        describe "submitting to the update action" do
          before { put user_path(user) }
          specify { response.should redirect_to(signin_path) }
        end
        
      end
      
      describe "when attempting to visit protected page" do
        before do
          visit edit_user_path(user)
          valid_sign_in(user)
        end
        
        describe "after being redirected and signing in" do
          it "should be redirected back to the original page" do
            page.should have_selector('legend', text: 'Edit profile')
          end
        end
      end
      
    end
    
    describe "for wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: 'wrong@example.com') }
      before { valid_sign_in(user) }
      
      describe "visiting Users#edit page" do
        before { visit edit_user_path(wrong_user) }
        it { should_not have_selector('legend', text: 'Edit profile') }
      end
      
      describe "submitting PUT to Users#update" do
        before { put user_path(wrong_user) }
        specify { response.should redirect_to(security_breach_path) }
      end
    end
    
    describe "for signed in editors" do
      let(:user) { FactoryGirl.create(:user, area_editor: true, author: false, referee: false) }
      before { valid_sign_in(user) }
      
      describe "visiting Users#index" do
        before { visit users_path }
        it { should have_link('New User') }
      end
    end
    
    describe "for signed in non-editors" do
      let(:user) { FactoryGirl.create(:user, author: true, referee: true) }
      before { valid_sign_in(user) }
      
      describe "visiting Users#index" do
        before { visit users_path }
        it { should_not have_link('New User') }
      end
    end
    
  end
  
end
