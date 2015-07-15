set :path, "/home/deployer/ergonaut/current"
set :output, "#{path}/log/cron.log"
job_type :runner,  "cd :path && . ~/.env && bin/rails runner -e :environment ':task' :output"

every 1.day, at: ['3:00 AM', '3:00 PM'] do
  runner "Submission.send_overdue_internal_review_reminders"
end

every 1.day, at: ['3:10 AM', '3:10 PM'] do
  runner "Submission.send_overdue_decision_based_on_external_review_reminders"
end

every 1.day, at: ['3:20 AM', '3:20 PM'] do
  runner "Submission.send_overdue_area_editor_assignment_reminders"
end

every 1.day, at: ['3:30 AM', '3:30 PM'] do
  runner "Submission.send_decision_approval_overdue_reminders"
end

every 1.day, at: ['3:40 AM', '3:40 PM'] do  
  runner "RefereeAssignment.send_overdue_response_reminders"
end

every 1.day, at: ['3:50 AM', '3:50 PM'] do  
  runner "RefereeAssignment.send_unanswered_reminder_notifications"
end

every 1.day, at: ['4:00 AM', '4:00 PM'] do
  runner "RefereeAssignment.send_report_due_soon_reminders"
end

every 1.day, at: ['4:10 AM', '4:10 PM'] do
  runner "RefereeAssignment.send_overdue_report_reminders"
end

every 1.day, at: '4:20 AM' do
  command "backup perform -t basic"
end