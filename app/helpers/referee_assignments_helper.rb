module RefereeAssignmentsHelper
  def attachment_link_or_none(attachment)
    if attachment.url
      link_to fa_icon('file-text') +
              ' ' +
              File.basename(attachment.url),
              attachment.url, target: '_blank'
    end
  end
end
