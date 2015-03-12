FactoryGirl.define do
  
  factory :sent_email do
    action                        'dummy_action'
    subject                       'Dummy Subject'
    to                            'foo@example.com'
    body                          'Dummy body... Lorem ipsum...'
  end
  
end