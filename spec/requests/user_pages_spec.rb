require 'spec_helper'

describe "User pages" do

  let(:user) { create(:user) }
  let(:area_editor) { create(:area_editor) }
  let(:managing_editor) { create(:managing_editor) }
  let(:submit) { 'Register' }
  subject { page }

  shared_examples_for "all actions are accessible" do
    # new
    describe "signup page" do
      before { visit signup_path }
      it { should have_content('New user') }
      it { should have_content('First name') }
    end

    describe "new user page" do
      before { visit new_user_path }
      it { should have_content('New user') }
      it { should have_content('First name') }
    end

    # create
    describe "create a new user" do
      before { visit new_user_path }

      context "entering valid information" do
        before do
          fill_in 'First name', with: 'Jane'
          fill_in 'Middle name', with: 'J.'
          fill_in 'Last name', with: 'Doe'
          fill_in 'Email', with: 'jane.doe@example.com'
          fill_in 'Affiliation', with: 'University of Janesville'
        end

        it "should create a new author/referee" do
          expect { click_button submit }.to change(User, :count).by(1)
          expect(User.last.referee?).to be_true
        end

        describe "after creating the new author/referee" do
          before { click_button submit }
          it { should have_success_message('successfully registered') }
        end
      end

      context "entering invalid information" do
        before do
          fill_in 'First name', with: ''
          fill_in 'Middle name', with: 'J.'
          fill_in 'Last name', with: 'Doe'
          fill_in 'Email', with: 'jane.doe@example.com'
          fill_in 'Affiliation', with: 'University of Janesville'
          click_button 'Register'
        end

        it "should not create a new user" do
          expect { click_button submit }.not_to change(User, :count)
        end

        describe "after failing to create a new user" do
          it { should have_error_message }
        end
      end
    end

    # fuzzy search
    describe "fuzzy search", js: true do
      before do
        @joe_schmo = create(:user, first_name: 'Joe', last_name: 'Schmo', email: 'jomo@example.com')
        visit users_path
      end

      it "has a search field" do
        expect(page).to have_field('Search')
      end

      context "when searching for an editor", js: true do
        before { fill_in 'Search', with: managing_editor.full_name }
        it "does show them in the search results" do
          expect(page).to have_link(managing_editor.full_name_affiliation_email)
        end
      end

      it "finds users fuzzily matched by name or email" do
        fill_in 'Search', with: 'Jo'
        click_link @joe_schmo.full_name_affiliation_email
        click_button('Go')
        expect(current_path).to eq(user_path(@joe_schmo))
      end
    end

    # show
    describe "show profile page" do
      before { visit user_path(user) }

      it { should have_content(user.first_name) }
      it { should have_content('Role') }
      it { should have_link('Edit profile') }
    end

    # index
    describe "index page" do
      before do
        30.times { FactoryGirl.create(:user) }
        visit users_path
      end

      it { should have_link('New User') }
      it { should have_link('Next') }
    end
  end

  context "when logged in as a managing editor" do
    before { valid_sign_in(managing_editor) }

    it_behaves_like "all actions are accessible"

    # create editor
    describe "create editor" do
      before { visit new_user_path }

      context "with valid information for a new managing editor" do
        before do
          fill_in 'First name', with: 'Jane'
          fill_in 'Middle name', with: 'J.'
          fill_in 'Last name', with: 'Doe'
          fill_in 'Email', with: 'jane.doe@example.com'
          fill_in 'Affiliation', with: 'University of Janesville'
          choose('Managing editor')
        end

        it "should create the user" do
          expect { click_button submit }.to change(User, :count).by(1)
          expect(User.last.email).to eq('jane.doe@example.com')
        end

        describe "after creating the user" do
          before { click_button submit }
          it { should have_success_message }
        end
      end

      context "with valid information for a new area editor" do
        before do
          fill_in 'First name', with: 'Jane'
          fill_in 'Middle name', with: 'J.'
          fill_in 'Last name', with: 'Doe'
          fill_in 'Email', with: 'jane.doe@example.com'
          fill_in 'Affiliation', with: 'University of Janesville'
          choose('Area editor')
        end

        it "should create a new area editor" do
          expect { click_button submit }.to change(User, :count).by(1)
          expect(User.last.email).to eq('jane.doe@example.com')
        end

        describe "after creating the user" do
          before { click_button submit }
          it { should have_success_message }
        end
      end
    end

    # edit
    describe "edit page" do
      before{ visit edit_user_path(user) }

      it { should have_content('Edit profile') }
      it { should have_content('Password') }
    end

    # update
    describe "update profile" do

      context "when the profile is own's" do
        before { visit edit_user_path(managing_editor) }

        describe "with invalid info" do
          before do
            fill_in 'First name', with: ''
            click_button 'Save'
          end
          it { should have_error_message }
        end

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            fill_in 'Password', with: user.password + '2'
            fill_in 'Confirm password', with: user.password + '2'
            choose 'Female'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Foo') }
          it { should have_content('Female') }
        end
      end

      context "when the profile is another managing editor's" do
        before do
          other_managing_editor = create(:managing_editor)
          visit edit_user_path(other_managing_editor)
        end

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            fill_in 'Password', with: user.password + '2'
            fill_in 'Confirm password', with: user.password + '2'
            choose 'Male'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Male') }
          it { should have_content('Foo') }
        end
      end

      context "when the profile is an area editor's" do
        before { visit edit_user_path(area_editor) }

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            fill_in 'Password', with: user.password + '2'
            fill_in 'Confirm password', with: user.password + '2'
            choose 'Female'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Female') }
          it { should have_content('Foo') }
        end
      end

      context "when the profile is an author/referee's" do
        before { visit edit_user_path(user) }

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            fill_in 'Password', with: user.password + '2'
            fill_in 'Confirm password', with: user.password + '2'
            choose 'Male'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Foo') }
          it { should have_content('Male') }
        end
      end
    end
  end

  shared_examples_for "updating gender info is not possible" do |redirect_path|
    describe "via the #update action" do
      before do
        put user_path(area_editor), user: { gender: 'Female' }
      end

      it "doesn't update the record; redirects to security breach" do
        expect(area_editor.reload.gender).not_to eq 'Female'
      end
    end

    describe "via the #update_gender action" do
      before do
        put update_gender_user_path(area_editor), user: { gender: 'Female' }
      end

      it "doesn't update the record; redirects to security breach" do
        expect(area_editor.reload.gender).not_to eq 'Female'
        expect(response).to redirect_to(send(redirect_path))
      end
    end
  end

  context "when logged in as an area editor" do
    before { valid_sign_in(area_editor) }

    it_behaves_like "all actions are accessible"

    # create editor
    describe "attempt to create a new editor" do
      before do
        @params = { first_name: 'Jane',
                   middle_name: 'J.',
                   last_name: 'Doe',
                   email: 'jane.doe@example.com',
                   affiliation: 'University of Janesville',
                   role: 'Managing editor'}
      end

      it "creates an author/referee, not an editor" do
        expect { post users_path, user: @params }.to change(User, :count)
        expect(User.last.editor?).to eq(false)
      end
    end

    describe "show editor's profile page" do
      before { visit user_path(managing_editor) }

      it { should have_content(managing_editor.first_name) }
      it { should have_content('Role') }
      it { should_not have_link('Edit profile') }
    end

    #edit
    describe "edit profile page for author/referee" do
      before{ visit edit_user_path(user) }

      it { should have_content('Edit profile') }
      it { should_not have_content ('Gender') }
    end

    describe "edit profile page for editor" do
      before{ visit edit_user_path(managing_editor) }

      it "redirects to security_breach_path" do
        expect(current_path).to eq(security_breach_path)
      end
    end

    #update
    describe "update profile" do

      context "when the profile is own's" do
        before { visit edit_user_path(area_editor) }

        describe "with invalid info" do
          before do
            fill_in 'First name', with: ''
            click_button 'Save'
          end
          it { should have_error_message }
        end

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            fill_in 'Password', with: user.password + '2'
            fill_in 'Confirm password', with: user.password + '2'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Foo') }
        end
      end

      context "when the profile is an editor's" do
        before do
          @other_area_editor = create(:area_editor)
          params = { first_name: 'changed',
                     last_name: 'different',
                     email: 'changed.different@altered.com' }
          put user_path(@other_area_editor), user: params
        end

        it "does not change the editor's profile" do
          @other_area_editor.reload
          expect(@other_area_editor.first_name).not_to eq('changed')
        end

        it "redirects to security_breach_path" do
          expect(response).to redirect_to(security_breach_path)
        end
      end

      context "when the profile is an author/referee's" do
        before { visit edit_user_path(user) }

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Foo') }
        end

        describe "with forbidden params" do
          before do
            @old_digest = user.password_digest
            params = { first_name: 'changed',
                       last_name: 'different',
                       email: 'changed.different@altered.com',
                       password: 'secret',
                       password_confirmation: 'secret' }
            put user_path(user), user: params
          end

          it "should change the permitted attributes" do
            expect(user.reload.first_name).to eq('changed')
          end

          it "should not change the forbidden attributes" do
            expect(user.reload.password_digest).to eq(@old_digest)
          end
        end
      end

      it_behaves_like "updating gender info is not possible", :security_breach_path
    end
  end

  context "when logged in as an author/referee" do
    before { valid_sign_in(user) }

    #new
    describe "signup page" do
      before { visit signup_path }
      it "should redirect to author center index" do
        expect(current_path).to eq(author_center_index_path)
      end
    end

    describe "new user page" do
      before { visit new_user_path }
      it "should redirect to author center" do
        expect(current_path).to eq(author_center_index_path)
      end
    end

    # fuzzy_search
    describe "fuzzy search" do
      before { post fuzzy_search_users_path, query: 'Jo Shmo' }

      it "redirects to signin" do
        expect(response).to redirect_to(security_breach_path)
      end
    end

    #create
    describe "attempt to create a new user" do
      before do
        @params = { first_name: 'Jane',
                    middle_name: 'J.',
                    last_name: 'Doe',
                    email: 'jane.doe@example.com',
                    affiliation: 'University of Janesville' }
      end

      it "fails to create a user" do
        expect { post users_path, user: @params }.not_to change(User, :count)
      end

      it "renders the new user page" do
        post users_path, user: @params
        expect(response.body).to match('New user')
      end
    end

    #show
    describe "show own profile page" do
      before { visit user_path(user) }

      it { should have_content(user.first_name) }
      it { should have_content('Role') }
      it { should have_link('Edit profile') }
    end

    describe "show another user's profile page" do
      before do
        @other_user = create(:user)
        visit user_path(@other_user)
      end

      it "redirects to security_breach_path" do
        expect(current_path).to eq(security_breach_path)
      end
    end

    #index
    describe "index page" do
      before { visit users_path }

      it "should redirect to security_breach_path" do
        expect(current_path).to eq(security_breach_path)
      end
    end

    #edit
    describe "edit profile page for self" do
      before{ visit edit_user_path(user) }

      it { should have_content('Edit profile') }
      it { should have_button('Save') }
      it { should_not have_content('Gender') }
    end

    describe "edit profile page for other author/referee" do
      before{ visit edit_user_path(create(:user)) }

      it "redirects to security_breach_path" do
        expect(current_path).to eq(security_breach_path)
      end
    end

    describe "edit profile page for editor" do
      before{ visit edit_user_path(area_editor) }

      it "redirects to security_breach_path" do
        expect(current_path).to eq(security_breach_path)
      end
    end

    #update
    describe "update profile" do

      context "when the profile is self's" do
        before { visit edit_user_path(user) }

        describe "with invalid info" do
          before do
            fill_in 'First name', with: ''
            click_button 'Save'
          end
          it { should have_error_message }
          it { should have_content('Edit profile') }
        end

        describe "with valid info" do
          before do
            fill_in 'First name', with: user.first_name + '2'
            fill_in 'Middle name', with: 'X.'
            fill_in 'Last name', with: user.last_name + '2'
            fill_in 'Email', with: user.email + '.ca'
            fill_in 'Affiliation', with: 'Foo'
            fill_in 'Password', with: user.password + '2'
            fill_in 'Confirm password', with: user.password + '2'
            click_button 'Save'
          end

          it { should have_success_message }
          it { should have_content(user.first_name + '2') }
          it { should have_content('X.') }
          it { should have_content(user.last_name + '2') }
          it { should have_content(user.email + '.ca') }
          it { should have_content('Foo') }
        end
      end

      context "when the profile is another user's" do
        before do
          @other_user = create(:user)
          @params = { first_name: 'changed',
                      last_name: 'altered',
                      email: 'changed.altered@example.com' }
          put user_path(@other_user), user: @params
        end

        it "fails to edit the user" do
          expect(@other_user.reload.first_name).not_to eq('changed')
        end

        it "redirects to security_breach_path" do
          expect(response).to redirect_to(security_breach_path)
        end
      end
    end

    it_behaves_like "updating gender info is not possible", :security_breach_path
  end

  context "when not logged in" do

    #new
    describe "signup page" do
      before { visit signup_path }
      it { should have_content('New user') }
      it { should have_content('First name') }
      it { should have_content('Middle name') }
      it { should have_content('Last name') }
      it { should have_content('Email') }
      it { should have_content('Affiliation') }
      it { should have_content('Password') }
      it { should have_content('Confirm password') }
      it { should have_button('Register') }
    end

    describe "new user page" do
      before { visit new_user_path }
      it { should have_content('New user') }
      it { should have_content('First name') }
      it { should have_content('Middle name') }
      it { should have_content('Last name') }
      it { should have_content('Email') }
      it { should have_content('Affiliation') }
      it { should have_content('Password') }
      it { should have_content('Confirm password') }
      it { should have_button('Register') }
    end

    # fuzzy_search
    describe "fuzzy search" do
      before { post fuzzy_search_users_path, query: 'Jo Shmo' }

      it "redirects to signin" do
        expect(response).to redirect_to(signin_path)
      end
    end

    #create
    describe "create user" do
      context "when going through signup page" do
        before do
          visit signup_path
          fill_in 'First name', with: 'New'
          fill_in 'Middle name', with: 'N.'
          fill_in 'Last name', with: 'User'
          fill_in 'Email', with: 'jane.doe@example.com'
          fill_in 'Affiliation', with: 'University of Janesville'
          fill_in 'Password', with: 'secret'
          fill_in 'Confirm password', with: 'secret'
          click_button submit
        end

        it "creates the user" do
          expect(User.last.first_name).to eq('New')
        end

        it { should have_success_message}

        it "redirects to author center" do
          expect(current_path).to eq(author_center_index_path)
        end
      end

      context "when already registered" do
        before do
          User.create(first_name: 'Existing', last_name: 'User', email: 'jane.doe@example.com', password: 'secret', password_confirmation: 'secret')
          visit signup_path
          fill_in 'First name', with: 'New'
          fill_in 'Last name', with: 'User'
          fill_in 'Email', with: 'jane.doe@example.com'
          fill_in 'Password', with: 'secret'
          fill_in 'Confirm password', with: 'secret'
          click_button submit
        end

        it "flashes an explanation and sends a password reset email instead of creating the user" do
          expect(page).to have_error_message('we\'re sending you an email')
          expect(User.where(first_name: 'New')).to be_empty
          expect(deliveries.last.body).to match('To reset your password, follow this')
        end
      end

      context "when posting directly with illicit attributes" do
        before do
          @params = { first_name: 'Jane',
                      middle_name: 'J.',
                      last_name: 'Doe',
                      email: 'jane.doe@example.com',
                      affiliation: 'University of Janesville',
                      role: 'Managing editor' }
        end

        it "fails to create a user" do
          expect { post users_path, user: @params }.not_to change(User, :count)
        end

        it "renders the new user page" do
          post users_path, user: @params
          expect(response.body).to match('New user')
        end
      end
    end

    #show
    describe "show profile page" do
      before do
        visit user_path(user)
      end

      it "redirects to signin path" do
        expect(current_path).to eq(signin_path)
      end
    end

    #index
    describe "index page" do
      before { visit users_path }

      it "should redirect to signin path" do
        expect(current_path).to eq(signin_path)
      end
    end

    #edit
    describe "edit profile page of some user" do
      before{ visit edit_user_path(create(:user)) }

      it "redirects to signin path" do
        expect(current_path).to eq(signin_path)
      end
    end

    #update
    describe "update profile of some user" do
      before do
        @params = { first_name: 'changed',
                    last_name: 'altered',
                    email: 'changed.altered@example.com' }
        put user_path(user), user: @params
      end

      it "fails to edit the user" do
        expect(user.reload.first_name).not_to eq('changed')
      end

      it "redirects to signin page" do
        expect(response).to redirect_to(signin_path)
      end
    end

    it_behaves_like "updating gender info is not possible", :signin_path
  end

end
