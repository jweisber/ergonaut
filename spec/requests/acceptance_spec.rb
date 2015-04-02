require 'spec_helper'

describe "Application" do
    
  let(:managing_editor) { create(:managing_editor) }
  
  it "manages the review process", js: true do
    
    # managing editor creates an area" do
    valid_sign_in(managing_editor)
    click_link 'Settings'
    fill_in 'area_name', with: 'Core Area'
    fill_in 'area_short_name', with: 'Core'
    within '#new_area' do
      click_button ''
    end
    expect(Area.last.name).to eq('Core Area')
    
    # managing editor registers an area editor"
    click_link 'Users'
    click_link 'New User'
    fill_in 'First name', with: 'Arye'
    fill_in 'Last name', with: 'Edit'
    fill_in 'Email', with: 'arye.edit@example.com'
    choose 'Area editor'
    click_button 'Register'
    area_editor = User.last
    area_editor.update_attributes(password: 'secret', password_confirmation: 'secret')
    expect(area_editor.email).to eq('arye.edit@example.com')
    click_link managing_editor.full_name
    click_link 'Sign out'
    
    
    # author registers
    visit root_path
    click_button 'Sign in'
    click_button 'Sign up'
    fill_in 'First name', with: 'Arthur'
    fill_in 'Middle name', with: 'A.'
    fill_in 'Last name', with: 'Author'
    fill_in 'Email', with: 'arthur.a.author@example.com'
    fill_in 'Affiliation', with: 'University of Authoria'
    fill_in 'Password', with: 'secret'
    fill_in 'Confirm password', with: 'secret'
    click_button 'Register'
    author = User.last
    author.password = author.password_confirmation = 'secret'
    expect(author.email).to eq('arthur.a.author@example.com')
    
    # author submits a paper"
    click_link 'Submit a paper'
    fill_in 'Title', with: 'My Clever Title'
    select 'Core Area', from: 'Area'
    attach_file 'File', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
    click_button 'Submit'
    sleep(1)
    submission = Submission.last
    expect(submission.title).to eq('My Clever Title')
    expect(deliveries).to include_email(subject_begins: 'New Submission', to: managing_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'New Submission', to: managing_editor.email)
    click_link author.full_name                                        
    click_link 'Sign out'
    
    
    # managing editor assigns an area editor
    valid_sign_in(managing_editor)
    click_link submission.title
    click_link 'Edit'
    select 'Arye Edit'
    click_button 'Save'
    expect(submission.area_editor.full_name).to eq(area_editor.full_name)
    expect(deliveries).to include_email(subject_begins: 'New Assignment', to: area_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'New Assignment', to: area_editor.email)
    click_link managing_editor.full_name
    click_link 'Sign out'
    
    
    # area editor logs in and looks over the submission
    valid_sign_in(area_editor)
    click_link submission.title
    click_link '"' + submission.title + '"'
    # TODO: find a test that works with PhantomJS/Poltergeist
    # expect(response_headers['Content-Type']).to eq 'application/pdf'

    # area editor assigns some referees
    visit submission_path(submission)
    click_link 'Add'
    fill_in 'First name', with: 'Referee'
    fill_in 'Last name', with: 'One'
    fill_in 'Email', with: 'referee.one@example.com'
    click_button 'new_user_submit_button'
    click_button 'Send'
    referee_one = User.find_by_email('referee.one@example.com')
    expect(deliveries).to include_email(subject_begins: 'Referee Request', to: referee_one.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Referee Request', to: referee_one.email)
    referee_one.update_attributes(password: 'secret', password_confirmation: 'secret')
    
    click_link 'Add'
    fill_in 'First name', with: 'Referee'
    fill_in 'Last name', with: 'Two'
    fill_in 'Email', with: 'referee.two@example.com'
    click_button 'new_user_submit_button'
    click_button 'Send'
    referee_two = User.find_by_email('referee.two@example.com')
    referee_two.update_attributes(password: 'secret', password_confirmation: 'secret')
    expect(deliveries).to include_email(subject_begins: 'Referee Request', to: referee_two.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Referee Request', to: referee_two.email)
    click_link area_editor.full_name
    click_link 'Sign out'                                    
    
    
    # some referees decline, two eventually accept
    visit decline_one_click_review_path(referee_one.referee_assignments.first.auth_token)
    fill_in 'Suggestions:', with: 'Ask someone else.'
    click_button 'Submit'
    expect(deliveries).to include_email(subject_begins: 'Referee Assignment Declined', to: area_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Referee Assignment Declined', to: area_editor.email)
    expect(deliveries).to include_email(subject_begins: 'Comments from', to: area_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Comments from', to: area_editor.email)
    click_link referee_one.full_name
    click_link 'Sign out'
    
    valid_sign_in(area_editor)
    click_link submission.title
    click_link 'Add'
    fill_in 'First name', with: 'Referee'
    fill_in 'Last name', with: 'Three'
    fill_in 'Email', with: 'referee.three@example.com'
    click_button 'new_user_submit_button'
    click_button 'Send'
    referee_three = User.find_by_email('referee.three@example.com')
    referee_three.update_attributes(password: 'secret', password_confirmation: 'secret')
    click_link area_editor.full_name
    click_link 'Sign out'
    
    valid_sign_in(referee_two)
    click_link submission.title
    choose 'referee_assignment_agreed_true'
    click_button 'Submit'
    click_link referee_two.full_name
    click_link 'Sign out'
    
    valid_sign_in(referee_three)
    click_link submission.title
    choose 'referee_assignment_agreed_true'
    click_button 'Submit'
    click_link referee_three.full_name
    click_link 'Sign out'


    # referees submit their reports
    valid_sign_in(referee_two)
    click_link submission.title
    fill_in 'referee_assignment_comments_for_author', with: 'Lorem ipsum dolor sit amet'
    attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
    fill_in 'referee_assignment_comments_for_editor', with: 'consectetur adipiscing elit'
    attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false    
    select Decision::MAJOR_REVISIONS
    click_button 'Submit'
    expect(deliveries).to include_email(subject_begins: 'Referee Report Completed', to: area_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Referee Report Completed', to: area_editor.email)
    click_link referee_two.full_name
    click_link 'Sign out'
    
    valid_sign_in(referee_three)
    click_link submission.title
    fill_in 'referee_assignment_comments_for_author', with: 'Lorem ipsum dolor sit amet'
    attach_file 'referee_assignment_attachment_for_author', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
    fill_in 'referee_assignment_comments_for_editor', with: 'consectetur adipiscing elit'
    attach_file 'referee_assignment_attachment_for_editor', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false    
    select Decision::MAJOR_REVISIONS
    click_button 'Submit'
    expect(deliveries).to include_email(subject_begins: 'Referee Report Completed', to: area_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Referee Report Completed', to: area_editor.email)
    click_link referee_three.full_name
    click_link 'Sign out'
    

    # area editor decides: major revisions
    valid_sign_in(area_editor)
    click_link submission.title
    click_link 'Edit'
    fill_in 'submission_area_editor_comments_for_managing_editors', with: 'Lorem ipsum dolor sit amet'
    fill_in 'submission_area_editor_comments_for_author', with: 'consectetur adipiscing elit'
    select Decision::MAJOR_REVISIONS
    click_button 'Save'
    expect(deliveries).to include_email(subject_begins: 'Decision Needs Approval', to: managing_editor.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Decision Needs Approval', to: managing_editor.email)
  
  
    # managing editor approves
    valid_sign_in(managing_editor)
    click_link submission.title
    click_link 'Edit'
    check 'submission_decision_approved'
    click_button 'Save'
    expect(deliveries).to include_email(subject_begins: 'Decision Regarding Submission', to: author.email)
    expect(SentEmail.all).to include_record(subject_begins: 'Decision Approved', to: area_editor.email)                                        
    click_link managing_editor.full_name
    click_link 'Sign out'
    

    # author submits a revised version
    valid_sign_in(author)
    click_link 'Needs revision'
    fill_in 'Title', with: 'My Clever Title'
    attach_file 'File', File.join(Rails.root, 'spec', 'support', 'Sample Submission.pdf'), visible: false
    click_button 'Submit'
    sleep(1)
    revised_submission = Submission.last
    click_link author.full_name
    click_link 'Sign out'
    
  
    # managing editors assign an area editor
    valid_sign_in(managing_editor)
    click_link revised_submission.title
    click_link 'Edit'
    select 'Arye Edit'
    click_button 'Save'
    expect(revised_submission.area_editor.full_name).to eq(area_editor.full_name)
    click_link managing_editor.full_name
    click_link 'Sign out'
  
  
    # area editor recruits the same referees
    valid_sign_in(area_editor)
    click_link revised_submission.title
    click_link 'Add'
    fill_in 'Search', with: referee_two.full_name
    click_link referee_two.full_name_affiliation_email
    find_button('existing_user_submit_button').trigger('click')
    click_button 'Send'
    
    click_link 'Add'
    fill_in 'Search', with: referee_three.full_name
    click_link referee_three.full_name_affiliation_email
    find_button('existing_user_submit_button').trigger('click')
    click_button 'Send'
    click_link area_editor.full_name
    click_link 'Sign out'
    
    valid_sign_in(referee_two)
    click_link submission.title
    choose 'referee_assignment_agreed_true'
    click_button 'Submit'
    click_link referee_two.full_name
    click_link 'Sign out'
    
    valid_sign_in(referee_three)
    click_link submission.title
    choose 'referee_assignment_agreed_true'
    click_button 'Submit'
    click_link referee_three.full_name
    click_link 'Sign out'
      
  
    # referees submit reports
    valid_sign_in(referee_two)
    click_link revised_submission.title
    fill_in 'referee_assignment_comments_for_author', with: 'Lorem ipsum dolor sit amet'
    fill_in 'referee_assignment_comments_for_editor', with: 'consectetur adipiscing elit'
    select Decision::ACCEPT
    click_button 'Submit'
    click_link referee_two.full_name    
    click_link 'Sign out'

    valid_sign_in(referee_three)
    click_link revised_submission.title
    fill_in 'referee_assignment_comments_for_author', with: 'Lorem ipsum dolor sit amet'
    fill_in 'referee_assignment_comments_for_editor', with: 'consectetur adipiscing elit'
    select Decision::REJECT
    click_button 'Submit'
    click_link referee_three.full_name    
    click_link 'Sign out'
  
  
    # area editor decides to accept
    valid_sign_in(area_editor)
    click_link revised_submission.title
    click_link 'Edit'
    fill_in 'submission_area_editor_comments_for_managing_editors', with: 'Lorem ipsum dolor sit amet'
    fill_in 'submission_area_editor_comments_for_author', with: 'consectetur adipiscing elit'
    select Decision::ACCEPT
    click_button 'Save'
    click_link area_editor.full_name
    click_link 'Sign out'


    # managing editors approve
    valid_sign_in(managing_editor)
    click_link revised_submission.title
    click_link 'Edit'
    check 'submission_decision_approved'
    click_button 'Save'
    
    revised_submission.reload    
    expect(revised_submission.decision).to eq(Decision::ACCEPT)
    expect(revised_submission.decision_approved).to be_true
    expect(revised_submission.archived).to be_true
    
  end
end