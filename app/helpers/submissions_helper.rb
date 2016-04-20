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

  def area_editor_histories_table
    string = <<-eos
      <table class='table table-striped table-condensed'>
        <thead>
          <tr>
            <th>Editor</th>
            <th>Active</th>
            <th>Done</th>
            <th>Latest</th>
          </tr>
        </thead>
        <tbody>
    eos

    done_hash = User.map_area_editor_ids_to_completed_assignment_counts
    active_hash = User.map_area_editor_ids_to_active_assignments_counts
    id_date_hashes = ActiveRecord::Base.connection.select_all('SELECT u.id, a.created_at FROM users u LEFT OUTER JOIN area_editor_assignments a ON u.id = a.user_id WHERE a.id IN (SELECT MAX(area_editor_assignments.id) FROM area_editor_assignments WHERE area_editor_assignments.user_id IS NOT NULL GROUP BY area_editor_assignments.user_id)')

    User.where(area_editor: true).order(:last_name).each do |ae|
      index = id_date_hashes.find_index {|i| i['id'] == ae.id}
      date = index ? (Date.parse id_date_hashes[index]['created_at'].to_s).strftime("%b. %-d, %Y") : "\u2014"

      string += <<-eos
        <tr>
          <td>#{ae.last_name}, #{ae.first_name}</td>
          <td style='text-align: center;'>#{active_hash[ae.id] ? active_hash[ae.id] : 0}</td>
          <td style='text-align: center;'>#{done_hash[ae.id] ? done_hash[ae.id] : 0}</td>
          <td>#{date}</td>
        </tr>
      eos
    end

    string += <<-eos
        </tbody>
      </table>
    eos
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
