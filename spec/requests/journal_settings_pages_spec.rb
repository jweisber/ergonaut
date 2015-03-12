require 'spec_helper'

describe "JournalSettings pages" do

  let(:user) { create(:user) }
  let(:area_editor) { create(:area_editor) }
  let(:managing_editor) { create(:managing_editor) }
  let(:current_settings) { JournalSettings.current }
  
  subject{ page} 
  
  context "when logged in as a managing editor" do
    before { valid_sign_in(managing_editor) }

    # index
    describe "index page" do
      before { visit journal_settings_path }

      it "redirects to the edit page" do
        expect(current_path).to eq(edit_journal_setting_path(current_settings))
      end
    end
    
    # edit 
    describe "edit page" do
      before { visit edit_journal_setting_path(current_settings) }
      
      it { should have_content('Areas') }
      it { should have_field('journal_settings_journal_email')}
      it { should have_content('Areas') }
      it { should have_field('area_name') }
      it { should have_content('Reports') }
      it { should have_field('journal_settings_number_of_reports_expected') }
      it { should have_content('Deadlines') }
      it { should have_field('journal_settings_days_to_assign_area_editor') }
      it { should have_content('Email Templates') }
      
      template_files_sans_extensions.each do |template|
        it "has a link to template: #{template} " do
          expect(page).to have_link('', href: show_email_template_journal_setting_path(template))
        end
      end
    end
    
    # show_email_template
    describe "show_email_template pages" do
      template_files_sans_extensions.each do |template|
        before { visit show_email_template_journal_setting_path(template) }
        
        it "shows the template page for #{template}" do
          expect(page).to have_content 'To'
          expect(page).to have_content 'Subject'
          expect(page).to have_content 'Body'
          expect(page).to have_content "render 'email_footer'"
        end
      end
    end
    
    # update
    describe "updating the journal's contact email with a valid address" do
      before do
        visit edit_journal_setting_path(current_settings)
        fill_in 'journal_settings_journal_email', with: 'foo@bar.com'
        page.all(:button, 'Save').first.click
      end
      
      it "changes the contact address" do
        expect(JournalSettings.journal_email).to eq('foo@bar.com')
      end
      
      it "shows the edit page again" do
        expect(page).to have_content('Areas')
      end
      
      it "flashes success" do
        expect(page).to have_success_message('saved')
      end
    end
    
    describe "updating the journal's contact email with invalid address" do
      before do
        @email_before = current_settings.journal_email
        visit edit_journal_setting_path(current_settings)
        fill_in 'journal_settings_journal_email', with: 'foo@bar'
        page.all(:button, 'Save').first.click   
      end
      
      it "does not change the contact address" do
        JournalSettings.current.reload
        expect(JournalSettings.current.journal_email).to eq(@email_before)
      end
      
      it "shows the edit page again" do
        expect(page).to have_content('Areas')
      end
      
      it "flashes failure" do
        expect(page).to have_error_message('Failed')
      end
    end
        
    describe "updating the number of required reports with valid data" do
      before do
        visit edit_journal_setting_path(current_settings)
        fill_in 'journal_settings_number_of_reports_expected', with: '5'
        page.all(:button, 'Save')[1].click
      end
      
      it "changes the number of reports required" do
        current_settings.reload
        expect(current_settings.number_of_reports_expected).to eq(5)
      end
      
      it "displays the edit page again and flashes success" do
        expect(page).to have_content('Areas')
        expect(page).to have_success_message('saved')
      end
    end
    
    describe "updating the number of required reports with invalid data" do
      before do
        visit edit_journal_setting_path(current_settings)
        fill_in 'journal_settings_number_of_reports_expected', with: 'foo'
      end
      
      it "does not change the number of reports required" do
        expect{ 
          page.all(:button, 'Save')[1].click 
        }.not_to change{current_settings.reload.number_of_reports_expected}
      end
      
      it "displays the edit page again and flashes an error" do
        page.all(:button, 'Save')[1].click 
        expect(page).to have_content('Areas')
        expect(page).to have_error_message('Failed')
      end
    end
    
    describe "updating deadlines with valid data" do
      before do
        visit edit_journal_setting_path(current_settings)
        fill_in 'journal_settings_days_to_assign_area_editor', with: '10'
        fill_in 'journal_settings_days_for_initial_review', with: '10'
        fill_in 'journal_settings_days_to_remind_area_editor', with: '10'
        fill_in 'journal_settings_days_to_respond_to_referee_request', with: '10'
        fill_in 'journal_settings_days_to_remind_unanswered_invitation', with: '10'
        fill_in 'journal_settings_days_for_external_review', with: '11'
        fill_in 'journal_settings_days_before_deadline_to_remind_referee', with: '10'
        fill_in 'journal_settings_days_to_remind_overdue_referee', with: '10'
        fill_in 'journal_settings_days_after_reports_completed_to_submit_decision', with: '10'
        fill_in 'journal_settings_days_to_remind_overdue_decision_approval', with: '10'
      end
      
      it "updates the deadline settings" do
        expect {
          page.all(:button, 'Save')[2].click
        }.to change{ current_settings.reload.days_to_assign_area_editor }.to(10)
        
      end
      
      it "displays the edit page again and flashes success" do
        page.all(:button, 'Save')[2].click
        expect(page).to have_content('Areas')
        expect(page).to have_success_message('saved')
      end
    end
    
    describe "updating deadlines with invalid data" do
      before do
        visit edit_journal_setting_path(current_settings)
        fill_in 'journal_settings_days_to_assign_area_editor', with: 'foo'
      end
      
      it "updates the deadline settings" do
        expect {
          page.all(:button, 'Save')[2].click
        }.not_to change{ current_settings.reload.days_to_assign_area_editor }
        
      end
      
      it "displays the edit page again and flashes an error" do
        page.all(:button, 'Save')[2].click
        expect(page).to have_content('Areas')
        expect(page).to have_error_message('Failed')
      end
    end
    
    # create_area
    describe "adding a new area with valid info" do
      before do
        visit edit_journal_setting_path(current_settings) 
        fill_in 'area_name', with: 'Some Area'
        fill_in 'area_short_name', with: 'S. Ar.'
      end
      
      it "increases the number of areas by 1" do
        expect{ click_button 'add_area_button' }.to change(Area, :count).by(1)
      end
      
      it "creates an area with the given name" do
        click_button 'add_area_button'
        expect(Area.find_by_name('Some Area')).not_to be_nil
        expect(Area.find_by_short_name('S. Ar.')).not_to be_nil
      end
      
      it "displays the edit page and flashes success" do
        click_button 'add_area_button'
        expect(page).to have_content('Areas')
        expect(page).to have_success_message('Area created')
      end
    end
    
    describe "\"adding\" (=restoring) a previously removed area" do
      before do
        @area = Area.create(name: 'Some Area', short_name: 'S. Ar.', removed: true)
        visit edit_journal_setting_path(current_settings) 
        fill_in 'area_name', with: 'Some Area'
        fill_in 'area_short_name', with: 'S. Ar.'
        click_button 'add_area_button'
      end
      
      it "restores the area" do
        expect(@area.reload.removed).to eq(false)
      end
      
      it "flashes success" do
        expect(page).to have_success_message 'Area restored'
      end
    end
    
    # remove_area
    describe "removing an area" do
      before do
        Area.create(name: 'Some Area', short_name: 'S. Ar.')
        visit edit_journal_setting_path(current_settings)
        select 'Some Area', from: 'remove_area_area_id'
        click_button 'remove_area_button'
      end
      
      it "removes the area" do
        expect(Area.find_by_name('Some Area')).to be_removed
        expect(page).not_to have_content('Some Area')
      end
      
      it "displays the edit page and flashes success" do
        expect(page).to have_content('Areas')
        expect(page).to have_success_message('Area removed')
      end
    end
    
  end
  
  shared_examples "a controller forbidden to users who aren't managing editors" do |redirect_path|
    # index
    describe "show journal settings" do
      before { visit show_email_template_journal_setting_path('notify_me_new_submission:') }
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
  
    # edit
    describe "edit journal settings" do
      before { visit edit_journal_setting_path(current_settings) }
    
      it "redirects to #{redirect_path}" do
        expect(current_path).to eq(send(redirect_path))
      end
    end
  
    # update
    describe "update journal settings" do
      before do
        @journal_settings = JournalSettings.current
        @new_journal_settings = @journal_settings.dup
        @new_journal_settings = { journal_email: 'new.address@example.com' }
        put journal_setting_path(@journal_settings), journal_settings: @new_journal_settings
      end
    
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    
      it "does not change the journal settings" do
        @journal_settings.reload
        expect(@journal_settings.journal_email).not_to eq('new.address@example.com')
      end
    end
  
    # create_area
    describe "creating an area" do
      before do
        @params = { name: 'Some Area', short_name: 'S. Ar.' }
        post create_area_journal_setting_path(current_settings), area: @params
      end
    
      it "does not create the area" do
        expect(Area.find_by_name('Some Area')).to be_nil
      end
    
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
  
    # remove_area
    describe "removing an area" do
      before do
        @area_to_remove = Area.create(name: 'Some Area', short_name: 'S. Ar.')
        @remove_area = { area_id: @area_to_remove.id }
        delete remove_area_journal_setting_path(current_settings), remove_area: @remove_area
      end
    
      it "does not remove the area" do
        expect(Area.find_by_name('Some Area')).not_to be_removed
      end
    
      it "redirects to #{redirect_path}" do
        expect(response).to redirect_to(send(redirect_path))
      end
    end
  end
  
  context "when logged in as an area editor" do
    before { valid_sign_in(area_editor) }
    
    it_behaves_like "a controller forbidden to users who aren't managing editors", :security_breach_path
  end
  
  context "when logged in as a author/referee" do
    before { valid_sign_in(area_editor) }
    
    it_behaves_like "a controller forbidden to users who aren't managing editors", :security_breach_path
  end
  
  context "when not logged in" do
    it_behaves_like "a controller forbidden to users who aren't managing editors", :signin_path
  end
end
