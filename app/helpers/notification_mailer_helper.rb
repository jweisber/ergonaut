module NotificationMailerHelper

  def humanize(n, options = { capitalize: false } )
    return n.to_s unless n.between?(0,10)
      
    english = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten']
    if options[:capitalize]
      return english[n].capitalize
    else
      return english[n]
    end
  end

  def report_for_area_editor(r)
    output = "Recommendation: #{ r.recommendation }\n\n"

    if r.comments_for_editor.blank? && r.attachment_for_editor.current_path.blank?
      output += "Comments for the Editor: none.\n\n"
    else
      if r.attachment_for_editor.current_path.blank?
        output += "Comments for the Editor: #{ r.comments_for_editor }\n\n"
      else
        output += "Comments for the Editor: see attached file.\n\n"
        output += "#{ r.comments_for_editor }\n\n" unless r.comments_for_editor.blank?
      end
    end

    if r.comments_for_author.blank? && r.attachment_for_author.current_path.blank?
      output += "Comments for the Author: none."
    else
      if r.attachment_for_author.current_path.blank?
        output += "Comments for the Author: #{ r.comments_for_author }"
      else
        output += "Comments for the Author: see attached file."
        output += "\n\n#{ r.comments_for_author }" unless r.comments_for_author.blank?
      end
    end

    return output
  end

  def report_for_author(r)
    output = "Referee #{r.referee_letter}\n---------\n"
    output += "Recommendation: #{r.recommendation}\n\n"
    output += "Comments for the Author: "
    output += "see attached file." unless r.attachment_for_author.current_path.blank?
    output += "\n\n" unless r.attachment_for_author.current_path.blank? || r.comments_for_author.blank?
    unless r.comments_for_author.blank?
      output += "#{r.comments_for_author}"
    else
      output += "none." if r.attachment_for_author.current_path.blank?
    end

    return output
  end

  def all_comments_for_author(submission)
    output = String.new

    if submission.area_editor_comments_for_author && !submission.area_editor_comments_for_author.to_s.empty?
      output += "\nComments from the Area Editor\n-----------------------------\n"
      output += submission.area_editor_comments_for_author.to_s
    end

    completed_assignments = submission.referee_assignments.where(report_completed: true)
    completed_assignments.each do |report|
      output += "\n\n#{report_for_author(report)}"
    end

    return output
  end

end