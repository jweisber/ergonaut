FactoryGirl.define do
  
  # factory :email_template do
#
#     factory :email_template_notify_me_new_submission do
#       action          'notify_me_new_submission'
#       description     'New Submission'
#       recipients      'Managing Editors'
#       subject         'New Submission'
#     end
#
#     factory :email_template_notify_ae_new_assignment do
#       action          'notify_ae_new_assignment'
#       description     'New Assignment'
#       recipients      'Area Editor'
#       subject         'New Assignment: "#{@submission.title}"'
#     end
#
#     factory :email_template_request_referee_report do
#       action          'request_referee_report'
#       description     'Referee Request'
#       recipients      'Referee'
#       subject         'Referee Request: #{@referee_assignment.submission.title}'
#     end
#
#     factory :email_template_notify_ae_referee_assignment_agreed do
#       action          'notify_ae_referee_assignment_agreed'
#       description     'Referee Agreed'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'Referee Agreed: #{@referee_assignment.referee.full_name}'
#     end
#
#     factory :email_template_confirm_assignment_agreed do
#       action          'confirm_assignment_agreed'
#       description     'Confirm: Referee Agreed'
#       recipients      'Referee'
#       subject         'Assignment Confirmation: #{@submission.title}'
#     end
#
#     factory :email_template_notify_au_decision_reached do
#       action          'notify_au_decision_reached'
#       description     'Notify: Decision Reached'
#       recipients      'Author'
#       subject         'Decision Regarding Submission: "#{@submission.title}"'
#     end
#
#     factory :email_template_re_thank_you do
#       action          're_thank_you'
#       description     'Thank Referee'
#       recipients      'Referee'
#       subject         'Thank you'
#     end
#
#     factory :email_template_notify_ae_decision_approved do
#       action          'notify_ae_decision_approved'
#       description     'Decision Approved'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'Decision Approved: "#{@submission.title}"'
#     end
#
#     factory :email_template_remind_ae_internal_review_overdue do
#       action          'remind_ae_internal_review_overdue'
#       description     'Internal Review Overdue'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'Overdue Internal Review: "#{@submission.title}"'
#     end
#
#     factory :email_template_notify_ae_all_reports_complete do
#       action          'notify_ae_all_reports_complete'
#       description     'All Referee Reports Complete'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'All Reports Complete for "#{@submission.title}"'
#     end
#
#     factory :email_template_notify_me_decision_needs_approval do
#       action          'notify_me_decision_needs_approval'
#       description     'Decision Needs Approval'
#       recipients      'Managing Editors'
#       subject         'Decision Needs Approval: Submission "#{@submission.title}"'
#     end
#
#     factory :email_template_notify_me_and_ae_submission_unarchived do
#       description     'Submission Unarchived'
#       recipients      'Managing Editors, Area Editor'
#       subject         'Unarchived: "#{@submission.title}"'
#     end
#
#     factory :email_template_cancel_referee_assignment do
#       action          'cancel_referee_assignment'
#       description     'Cancel Referee Assignment'
#       recipients      'Referee'
#       subject         'Cancelled Referee Request: #{@submission.title}'
#     end
#
#     factory :email_template_notify_ae_report_completed do
#       action          'notify_ae_report_completed'
#       description     'Referee Assignment Completed'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'Referee Report Completed: "#{@submission.title}"'
#     end
#
#     factory :email_template_remind_ae_decision_based_on_external_reviews_overdue do
#       action          'remind_ae_decision_based_on_external_reviews_overdue'
#       description     'Decision Overdue'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'Overdue Decision: "#{@submission.title}"'
#     end
#
#     factory :email_template_remind_managing_editors_assignment_overdue do
#       action          'remind_managing_editors_assignment_overdue'
#       description     'Area Editor Assignment Overdue'
#       recipients      'Managing Editors'
#       subject         'Reminder: Assignment Needed'
#     end
#
#     factory :email_template_remind_managing_editors_decision_approval_overdue do
#       action          'remind_managing_editors_decision_approval_overdue'
#       description     'Decision Approval Overdue'
#       recipients      'Managing Editors'
#       subject         'Reminder: Decision Needs Approval'
#     end
#
#     factory :email_template_remind_re_response_overdue do
#       action          'remind_re_response_overdue'
#       description     'Remind: Response to Referee Request Overdue'
#       recipients      'Referee'
#       subject         'Reminder to Respond'
#     end
#
#     factory :email_template_notify_ae_response_reminder_unanswered do
#       action          'notify_ae_response_reminder_unanswered'
#       description     'Notify: Referee Request Unanswered Despite Reminder'
#       recipients      'Area Editor (cc Managing Editors)'
#       subject         'Referee Request Still Unanswered: "#{@referee_assignment.referee.full_name}"'
#     end
#
#     factory :email_template_remind_re_report_due_soon do
#       action          'remind_re_report_due_soon'
#       description     'Remind: Report Due Soon'
#       recipients      'Referee'
#       subject         'Early Reminder: Report Due #{@referee_assignment.date_due_pretty}'
#     end
#
#     factory :email_template_remind_re_report_overdue do
#       action          'remind_re_report_overdue'
#       description     'Remind: Report Overdue'
#       recipients      'Referee'
#       subject         'Overdue Report'
#     end
#
#     factory :email_template_notify_re_outcome do
#       action          'notify_re_outcome'
#       description     'Notify Referee of Outcome'
#       recipients      'Referee'
#       subject         'Outcome & Thank You'
#     end
#
#     factory :email_template_notify_ae_or_me_referee_request_declined do
#       action          'notify_ae_or_me_referee_request_declined'
#       description     'Referee Assignment Declined'
#       recipients      'Area Editor (or else Managing Editors)'
#       subject         'Referee Assignment Declined: #{@referee_assignment.referee.full_name}'
#     end
#
#     factory :email_template_notify_ae_assignment_canceled do
#       action           'notify_ae_assignment_canceled'
#       description      'Area Editor Assignment Cancelled'
#       recipients       'Area Editor'
#       subject          'Assignment Canceled: "#{@submission.title}"'
#       body             ""
#     end
#
#     factory :email_template_notify_creator_registration do
#       action           'notify_creator_registration'
#       description      'Notification of Registration'
#       recipients       'User'
#       subject          "You've been registered with Ergo"
#     end
#
#   end
  
end