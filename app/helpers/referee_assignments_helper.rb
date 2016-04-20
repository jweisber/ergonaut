module RefereeAssignmentsHelper
  def attachment_link_or_none(attachment)
    if attachment.url
      link_to fa_icon('file-text') +
              ' ' +
              File.basename(attachment.url),
              attachment.url, target: '_blank'
    end
  end

  def show_hide_report_button_label(assignment)
  	if assignment.hide_report_from_author
  		'Unhide'
  	else
  		'Hide'
  	end
  end
end
