module RefereeAssignmentReminders
  
  def send_overdue_response_reminders
    puts "========== send_overdue_response_reminders =========="
    puts "[ #{Time.now} ]:"
    RefereeAssignment.overdue_response_reminder_needed.each do |ra|
      NotificationMailer.remind_re_response_overdue(ra).save_and_deliver(same_thread: true)
    end
    puts "====================================================="
  end
  
  def send_unanswered_reminder_notifications
    puts "======= send_unanswered_reminder_notifications ======"
    puts "[ #{Time.now} ]:"
    RefereeAssignment.unanswered_reminder_notification_needed.each do |ra|
      NotificationMailer.notify_ae_response_reminder_unanswered(ra).save_and_deliver(same_thread: true)
    end
    puts "====================================================="
  end

  def send_report_due_soon_reminders
    puts "========== send_report_due_soon_reminders ==========="
    puts "[ #{Time.now} ]:"
    RefereeAssignment.report_due_soon_reminder_needed.each do |ra|
      NotificationMailer.remind_re_report_due_soon(ra).save_and_deliver(same_thread: true)
    end
    puts "====================================================="
  end

  def send_overdue_report_reminders
    puts "=========== send_overdue_report_reminders ==========="
    puts "[ #{Time.now} ]:"
    RefereeAssignment.overdue_report.each do |assignment|
      new_deadline = assignment.report_due_at + JournalSettings.days_to_extend_missed_report_deadlines.days
      assignment.update_attributes(report_due_at: new_deadline)
      assignment.reload
      NotificationMailer.remind_re_report_overdue(assignment).save_and_deliver(same_thread: true)
    end
    puts "====================================================="
  end

end