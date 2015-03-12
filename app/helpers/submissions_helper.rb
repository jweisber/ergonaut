module SubmissionsHelper
  
  def placeholder_text(symbol)
    if symbol == :area_editor_comments_for_managing_editors
      "Confidential to the managing editors: a brief explanation of the rationale for the decision."
    elsif symbol == :area_editor_comments_for_author
      "Will be shared with any referees. Required for major/minor revisions, optional otherwise."
    end
  end
  
  def submission_tr_class_for_area_editor(s)
    if s.archived?
      ''
    elsif s.initial_review_overdue? ||
       s.has_overdue_referee_assignments? ||
       s.area_editor_decision_based_on_external_review_overdue?
      "error"
    elsif s.in_initial_review? || !s.has_enough_referee_assignments? || s.post_external_review?
      "warning"
    else
      ""
    end
  end
  
  def submission_tr_class_for_managing_editor(s)
    if s.archived?
      ''
    elsif s.area_editor_assignment_overdue? || 
       s.initial_review_overdue? || 
       !s.has_enough_referee_assignments? ||
       s.has_overdue_referee_assignments? ||
       s.area_editor_decision_based_on_external_review_overdue? ||
       s.decision_approval_overdue?
      'error'
    elsif s.pre_initial_review? || s.post_external_review?
      'warning'
    else
      ''
    end
  end
  
  def referee_assignment_tr_class(ra)
    
    if ra.awaiting_response?
      
      if ra.response_overdue?
        'error'
      else
        'warning'
      end
      
    elsif ra.agreed?
      
      if ra.report_completed?
        'success'
      elsif ra.report_overdue?
        'error'
      else
        'info'
      end
      
    elsif ra.declined?
      
      ''
      
    end
    
  end
  
end
