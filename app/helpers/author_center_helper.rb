module AuthorCenterHelper
  def confirm_withdraw_message
    "Are you sure you want to withdraw this submission from consideration?"
  end

  def date_agreed_or_declined(assignment)
		if assignment.agreed
			assignment.date_agreed_pretty
		else
			assignment.date_declined_pretty
		end
  end

  def agreed_y_or_n(assignment)
		if assignment.agreed
			'Y'
		elsif assignment.agreed.nil?
			"\u2014"
		else
			'N'
		end
  end

  def date_due(assignment)
		if assignment.agreed
			assignment.date_due_pretty
		else
			"\u2014"
		end
  end

  def report_completed_date_and_link(assignment)
  	if assignment.report_completed && Time.now > assignment.report_completed_at + 2.days
  		link_to assignment.date_completed_pretty,
              author_center_referee_assignment_path(assignment.submission, assignment)
  	else
  		"\u2014"
  	end
  end

  def status_for_author_switch(submission)
    if submission.withdrawn?
      'Withdrawn'
    elsif submission.review_approved?
      submission.decision
    elsif submission.review_complete?
      'Decision submitted, awaiting approval'
    elsif submission.post_external_review?
      'Awaiting decision'
    elsif submission.in_external_review?
      'External review'
    elsif submission.in_initial_review?
      'Initial review<br />An area editor has been assigned and is reviewing your submission.'
    elsif submission.pre_initial_review?
      'Awaiting assignment to an area editor'
    else
      '\u2014'
    end
  end

  def submission_status_for_author(submission)
    out = status_for_author_switch(submission)

		if submission.decision_approved
			out += " \u2014 " + pretty_date(submission.decision_entered_at)
		end

    if submission.review_approved? && !submission.area_editor_comments_for_author.blank?
      link_to out, '#',
                   class: 'popover-link',
                   placement: 'left',
                   'data-trigger' => 'click',
                   'data-content' => "<h4>Editor's comments</h4>#{ simple_format(submission.area_editor_comments_for_author) }"
     else
       out
     end
  end

end