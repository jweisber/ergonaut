module SubmissionStatusCheckers
  
  # stage
  
  def pre_initial_review?
    area_editor.nil? && non_canceled_referee_assignments.size == 0
  end
  
  def in_initial_review?
    !area_editor.nil? && 
    non_canceled_referee_assignments.size == 0 && 
    !review_complete? &&
    !review_approved?
  end
  
  def in_external_review?
    non_canceled_referee_assignments.size > 0 && (!has_enough_reports? || has_incomplete_referee_assignments?)
  end
  
  def post_external_review?
    has_enough_reports? &&
    !has_incomplete_referee_assignments? &&
    !review_complete?
  end
  
  def review_complete?
    decision != Decision::NO_DECISION && !decision_approved
  end
  
  def review_approved?
    decision != Decision::NO_DECISION && decision_approved
  end
  
  
  # initial review
  
  def area_editor_assigned?
    !area_editor_assignment.nil?
  end
  
  def area_editor_assignment_overdue?
    pre_initial_review? && Time.current > created_at + JournalSettings.days_to_assign_area_editor.days
  end
  
  def initial_review_overdue?
    in_initial_review? && Time.current > created_at + JournalSettings.days_for_initial_review.days
  end


  # external review

  def referee_assigned?
    referee_assignments.size > 0
  end
  
  def external_review?
    non_canceled_referee_assignments.size > 0
  end
  
  def has_incomplete_referee_assignments?
    non_canceled_non_declined_referee_assignments.each do |ra|
      return true unless ra.report_completed?
    end
    return false
  end
  
  def last_report_due_at
    assignments = non_canceled_non_declined_referee_assignments
    assignments.delete_if { |ra| ra.report_due_at.nil? } # temporary: until old data from pre-default days is cleared out
    assignments.sort { |a,b| a.report_due_at <=> b.report_due_at }
    assignments.last ? assignments.last.report_due_at : nil 
  end
  
  def last_report_completed_at
    assignments = non_canceled_non_declined_referee_assignments
    assignments.delete_if { |ra| !ra.report_completed }
    assignments.sort { |a,b| a.report_completed_at <=> b.report_completed_at }
    assignments.reverse.last.report_completed_at
  end
  
  def has_enough_referee_assignments?
    return true unless in_external_review?
    non_canceled_non_declined_referee_assignments.size >= JournalSettings.number_of_reports_expected
  end
  
  def has_enough_reports?
    completed_assignments = non_canceled_non_declined_referee_assignments.delete_if { |ra| !ra.report_completed }
    completed_assignments.size >= JournalSettings.number_of_reports_expected
  end
  
  def needs_more_reports?
    self.external_review? && !self.has_enough_reports?
  end
  
  def has_overdue_referee_assignments?
    return false unless in_external_review?
    pending_referee_assignments.each do |r|
      return true if Time.current > r.report_due_at
    end
    false
  end
  
  def referee_reports_complete?
    if self.referee_assignments.length == 0
      return false
    else
      self.referee_assignments.each do |a|
        return false if !(!a.agreed || a.report_completed?)
      end
      return true
    end
  end
  
  
  # post-external review
  
  def area_editor_decision_based_on_external_review_overdue?
    post_external_review? && Time.current > last_report_completed_at + JournalSettings.days_after_reports_completed_to_submit_decision.days
  end
  
  def decision_approval_overdue?
    review_complete? && Time.current > decision_entered_at + JournalSettings.days_to_remind_overdue_decision_approval.days
  end
  
  
  # display

  def display_status_for_editors
    if review_approved?
      "#{decision}"
    elsif review_complete?
      'Decision needs approval'
    elsif post_external_review?
      'Needs decision'
    elsif in_external_review?
      'Awaiting reports'
    elsif in_initial_review?
      'Initial review'
    elsif pre_initial_review?
      'Needs area editor'
    else
      '\u2014'
    end
  end
  
end