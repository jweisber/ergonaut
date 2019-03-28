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

  def area_editor_histories_table(submission)

    assignments = AreaEditorAssignment.where("created_at > ?", Time.now - 3.months)
                                      .where("user_id IS NOT NULL AND submission_id IS NOT NULL")
                                      .includes(:submission, :area_editor)
    area_editors = User.where(area_editor: true)
    
    editors_hash = Hash.new
    area_editors.each do |editor|
      dates = assignments.select { |a| a.area_editor == editor}
                         .map(&:created_at)
                         .sort { |a, b| b <=> a }
      editors_hash[editor.full_name] = dates
    end

    area_editors.sort! do |a, b|
      a_dates = editors_hash[a.full_name]
      b_dates = editors_hash[b.full_name]

      if a_dates.present? && b_dates.present?
        a_dates[0] <=> b_dates[0]
      else
        a_dates.present? ? 1 : -1
      end
    end

    editors_in_area = area_editors.select{ |editor| editor.editor_area_id == submission.area_id}
    editors_outside_area = area_editors.select{ |editor| editor.editor_area_id != submission.area_id}

    string = String.new

    if editors_in_area.present?
      string += <<-eos
        <h4>#{submission.area.short_name} Editors</h4>
        <table class='table table-striped table-condensed'>
        <tbody>
      eos

      editors_in_area.each do |editor|
        dates = editors_hash[editor.full_name]
        string += <<-eos
          <tr>
            <td>#{editor.full_name}</td>
        eos

        if dates.present?
          string += "<td>#{pretty_date(dates.shift)}</td>"
          dates.each { |d| string += "<tr><td>&nbsp;</td><td>#{pretty_date(d)}</td></tr>" }
        else
          string += "<td>No Recent Assignments</td>"
        end
      end
      
      string += <<-eos
          </tbody>
        </table>
      eos
    end

    if editors_outside_area.present?
      string += <<-eos
        <h4>Other Editors</h4>
        <table class='table table-striped table-condensed'>
        <tbody>
      eos

      editors_outside_area.each do |editor|
        dates = editors_hash[editor.full_name]
        string += <<-eos
          <tr>
            <td>#{editor.full_name}</td>
        eos

        if dates.present?
          string += "<td>#{pretty_date(dates.shift)}</td>"
          dates.each { |d| string += "<tr><td>&nbsp;</td><td>#{pretty_date(d)}</td></tr>" }
        else
          string += "<td>No Recent Assignments</td>"
        end
      end
      
      string += <<-eos
          </tbody>
        </table>
      eos
    end

    string.html_safe
  end

  def due_date_text_or_link(s,r)
    text = (r.awaiting_response? || r.agreed) ? r.date_due_pretty : "\u2014".html_safe
    text = 'Canceled' if r.canceled

    if current_user.managing_editor? && (r.awaiting_response? || r.awaiting_report?)
      text = link_to(text, edit_due_date_submission_referee_assignment_path(s,r))
    end

    return text
  end

  def gender_icon(gender)
    if gender == 'Female'
      return fa_icon('venus').html_safe
    elsif gender == 'Male'
      return fa_icon('mars').html_safe
    else
      return fa_icon('genderless').html_safe
    end
  end

  def gender_popover_link(user)
    @user = user
    content = render 'shared/update_gender_popover'
    link_to(gender_icon(@user.gender),
            '#',
            id: "gender_popover_link",
            style: "width: 1em; display: inline-block;",
            class: "popover-link",
            placement: "right",
            "data-content" => %Q[#{content}])
  end

  def report_link_text(assignment)
    if assignment.hide_report_from_author
      'Hidden'
    else
      'View report'
    end
  end

  def show_cancel_button?(assignment)
    !assignment.canceled && !assignment.report_completed && !assignment.declined?
  end
end
