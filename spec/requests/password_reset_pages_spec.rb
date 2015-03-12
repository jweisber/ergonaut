require 'spec_helper'

describe "Password reset pages" do
  
  let(:user) { create(:user) }
  
  # new
  describe "new password rest" do
    before { visit new_password_reset_path }
    
    it "presents a form for requesting a password reset email" do
      expect(page).to have_selector('label', text: 'Email')
      expect(page).to have_button('Email me')
    end
  end
  
  # create
  describe "create password reset" do
    
    context "using a registered email address" do
      before do
        visit new_password_reset_path(user)
        fill_in 'Email', with: user.email
        click_button 'Email me'
      end
    
      it "redirects to signin and flashes success" do
        expect(current_path).to eq(signin_path)
        expect(page).to have_success_message('sent')
      end
    
      it "sends a password reset email" do
        expect(deliveries).to include_email(subject: 'Password Reset', to: user.email)
        expect(SentEmail.all).to include_record(subject: 'Password Reset', to: user.email)
      end
    end
    
    context "using an unregistered email address" do
      before do
        visit new_password_reset_path(user)
        fill_in 'Email', with: 'non.user@example.com'
        click_button 'Email me'
      end
    
      it "re-renders the form and flashes an error" do
        expect(page).to have_selector('label', text: 'Email')
        expect(page).to have_button('Email me')
        expect(page).to have_error_message('can\'t find')
      end
    
      it "does not send an email" do
        expect(deliveries).not_to include_email(subject: 'Password Reset')
        expect(SentEmail.all).not_to include_record(subject: 'Password Reset')
      end
    end
  end
  
  # edit
  describe "edit password" do
    before do
      visit new_password_reset_path(user)
      fill_in 'Email', with: user.email
      click_button 'Email me'
      visit edit_password_reset_path(user.reload.password_reset_token) 
    end
    
    it "presents a password reset form" do
      expect(page).to have_field('New password')
      expect(page).to have_field('Confirm password')
      expect(page).to have_button('Change')
    end
  end
  
  # update
  describe "update password" do
    before do
      visit new_password_reset_path(user)
      fill_in 'Email', with: user.email
      click_button 'Email me'
      visit edit_password_reset_path(user.reload.password_reset_token)
    end
    
    context "with a valid password" do
      before do
        fill_in 'New password', with: 'new_secret'
        fill_in 'Confirm password', with: 'new_secret'
        click_button 'Change'
      end
    
      it "updates the user's password" do
        user.reload
        expect(user.authenticate('new_secret')).to be_true
      end
    
      it "changes the user's password reset token" do
        old_token = user.password_reset_token
        user.reload
        expect(user.password_reset_token).not_to eq(old_token)
      end
    
      it "signs the user in" do
        expect(page).to have_content(user.full_name)
      end
    
      it "redirects to the user's home path" do
        expect(current_path).to eq(author_center_index_path)
      end
    
      it "flashes success" do
        expect(page).to have_success_message('Your password has been reset')
      end
    end
    
    context "with invalid password info" do
      before do
        fill_in 'New password', with: 'new_secret'
        fill_in 'Confirm password', with: 'different_secret'
        click_button 'Change'
      end
      
      it "doesn't update the user's password" do
        user.reload
        expect(user.authenticate('new_secret')).not_to be_true
      end
    
      it "doesn't change the user's password reset token" do
        old_token = user.password_reset_token
        user.reload
        expect(user.password_reset_token).to eq(old_token)
      end
    
      it "doesn't sign the user in" do
        expect(page).not_to have_content(user.full_name)
      end
    
      it "re-renders the form" do
        expect(page).to have_field('New password')
        expect(page).to have_field('Confirm password')
        expect(page).to have_button('Change')
      end
    
      it "flashes failure" do
        expect(page).to have_error_message('Couldn\'t reset')
      end
    end
  end

  context "when reset token doesn't exist" do
    # edit
    describe "edit password" do
      before { visit edit_password_reset_path('foo') }
      
      it "flashes an error and renders the form for a new reset link" do
        expect(page).to have_error_message('Invalid')
        expect(page).to have_button('Email me')
      end
    end
    
    # update
    describe "update password" do
      before do
        put password_reset_path('foo'), user: { password: 'foobar', password_confirmation: 'foobar' }
      end
      
      it "flashes an error and renders the form for a new reset link" do
        expect(response.body).to match('Invalid')
        expect(response.body).to match('Email me')
      end
      
      it "leaves password unchanged" do
        expect(user.reload.authenticate('foobar')).not_to be_true
      end
    end
  end
  
  context "when reset token is expired" do
    # edit
    describe "edit password" do
      before do
        visit new_password_reset_path(user)
        fill_in 'Email', with: user.email
        click_button 'Email me'
        user.update_attributes(password_reset_sent_at: 121.minutes.ago)
        visit edit_password_reset_path(user.reload.password_reset_token)
      end
      
      it "flashes an error and renders the form for a new reset link" do
        expect(page).to have_error_message('expired')
        expect(page).to have_button('Email me')
      end
    end
    
    # update
    describe "update password" do
      before do
        visit new_password_reset_path(user)
        fill_in 'Email', with: user.email
        click_button 'Email me'
        user.update_attributes(password_reset_sent_at: 121.minutes.ago)
        put password_reset_path(user.reload.password_reset_token),
            user: { password: 'foobar', password_confirmation: 'foobar' }
      end
      
      it "flashes an error and renders the form for a new reset link" do
        expect(response.body).to match('expired')
        expect(response.body).to match('Email me')
      end
      
      it "leaves password unchanged" do
        expect(user.reload.authenticate('foobar')).not_to be_true
      end
    end
  end

end