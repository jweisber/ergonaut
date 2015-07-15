module SubmissionReminders

  def send_overdue_internal_review_reminders
    puts "====== send_overdue_internal_review_reminders ======="
    puts "[ #{Time.now} ]:"
    Submission.internal_review_reminder_needed.each do |s|
      NotificationMailer.remind_ae_internal_review_overdue(s).save_and_deliver(same_thread: true)
    end
    puts "====================================================="    
  end

  def send_overdue_decision_based_on_external_review_reminders
    puts "= send_overdue_decision_based_on_external_review_reminders ="
    puts "[ #{Time.now} ]:"
    Submission.area_editor_decision_based_on_external_reviews_overdue.each do |s|
      NotificationMailer.remind_ae_decision_based_on_external_reviews_overdue(s).save_and_deliver(same_thread: true)
    end
    puts "============================================================"    
  end
  
  def send_overdue_area_editor_assignment_reminders
    puts "=== send_overdue_area_editor_assignment_reminders ==="
    puts "[ #{Time.now} ]:"
    Submission.area_editor_assignment_reminder_needed.each do |s|
      NotificationMailer.remind_managing_editors_assignment_overdue(s).save_and_deliver(same_thread: true)
    end
    puts "====================================================="
  end
  
  def send_decision_approval_overdue_reminders
    puts "====== send_decision_approval_overdue_reminders ====="
    puts "[ #{Time.now} ]:"
    Submission.decision_approval_reminder_needed.each do |s|
      NotificationMailer.remind_managing_editors_decision_approval_overdue(s).save_and_deliver(same_thread: true)
    end
    puts "====================================================="
  end

end