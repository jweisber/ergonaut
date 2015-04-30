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
end