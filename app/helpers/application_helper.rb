module ApplicationHelper

  def area_editor_or_emdash(submission)
		if submission.area_editor
			link_to(submission.area_editor.full_name, user_path(submission.area_editor)).html_safe
		else
			'&mdash;'.html_safe
		end
  end

  def pretty_date(datetime)
    datetime ? datetime.strftime("%b. %-d, %Y") : "\u2014"
  end

  def header_logo
    if Rails.env.development?
      link_to "ErgoDev", "/about", id: "logo"
    else
      link_to "Ergo", "/about", id: "logo"
    end
  end

  def bread_crumbs

    @bread_crumbs = Array.new

    # SUBMISSIONS
    if controller_name == 'submissions'
      #@bread_crumbs.push BreadCrumb.new("Review", submissions_path) unless action_name == 'index'
      if action_name == "show"
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:id]}", submission_path(params[:id]))
      elsif action_name == "edit" || action_name == "update"
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:id]}", submission_path(params[:id]))
        @bread_crumbs.push BreadCrumb.new("Edit", edit_submission_path(params[:id]))
      elsif action_name == "edit_manuscript_file"
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:id]}", submission_path(params[:id]))
        @bread_crumbs.push BreadCrumb.new('Replace manuscript', '#')
      elsif action_name == 'update_manuscript_file'
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:id]}", submission_path(params[:id]))
      end
    end

    # ARCHIVES
    if controller_name == 'archives'
      #@bread_crumbs.push BreadCrumb.new("Review", submissions_path)
      @bread_crumbs.push BreadCrumb.new("Archives", archives_path)
      if action_name == "show"
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:id]}", archive_path(params[:id]))
      end
    end

    # USERS
    if controller_name == 'users'

      # logged in?
      if current_user

        if action_name.in? ['show', 'edit', 'update']
          # own profile?
          if current_user && current_user.id == params[:id].to_i
            #@bread_crumbs.push BreadCrumb.new("Users", users_path) if current_user.editor?
            @bread_crumbs.push BreadCrumb.new("My profile", user_path(params[:id])) if current_user.editor?
            if action_name.in? ["edit", "update"]
              @bread_crumbs.push BreadCrumb.new("My profile", user_path(params[:id])) if !current_user.editor?
              @bread_crumbs.push BreadCrumb.new("Edit", edit_user_path(params[:id]))
            end
          # third-party's profile
          else
            #@bread_crumbs.push BreadCrumb.new("Users", users_path) unless action_name == 'index'
            if action_name == "show"
              @bread_crumbs.push BreadCrumb.new("User \##{params[:id]}", user_path(params[:id]))
            elsif action_name.in? ["edit", "update"]
              @bread_crumbs.push BreadCrumb.new("User \##{params[:id]}", user_path(params[:id]))
              @bread_crumbs.push BreadCrumb.new("Edit", edit_user_path(params[:id]))
            end
          end
        end
      end
    end

    # REFEREE_ASSIGNMENTS
    if controller_name == 'referee_assignments'
      if ['new', 'create', 'select_existing_user', 'register_new_user'].include? action_name
        #@bread_crumbs.push BreadCrumb.new("Review", submissions_path) unless action_name == 'index'
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:submission_id]}", submission_path(params[:submission_id]))
        @bread_crumbs.push BreadCrumb.new("Assign referee", new_submission_referee_assignment_path)
        if ['select_existing_user', 'register_new_user'].include? action_name
          @bread_crumbs.push BreadCrumb.new("Email", new_submission_referee_assignment_path)
        end
      elsif action_name == "edit"
        #@bread_crumbs.push BreadCrumb.new("Referee", referee_center_index_path) unless action_name == 'index'
        @bread_crumbs.push BreadCrumb.new("Invitation to review submission \##{params[:submission_id]}", submission_referee_assignment_path(params[:id]))
      elsif action_name == "show"
        @submission = Submission.find(params[:submission_id]) if params[:submission_id]
        @submission = Submission.find(params[:author_center_id]) if params[:author_center_id]
        @submission = Submission.find(params[:archive_id]) if params[:archive_id]
        if @submission.archived?
          if params[:archive_id]
            #@bread_crumbs.push BreadCrumb.new("Review", submissions_path)
            @bread_crumbs.push BreadCrumb.new("Archives", archives_path) unless action_name == 'index'
            @bread_crumbs.push BreadCrumb.new("Submission \##{params[:archive_id]}", archive_path(params[:archive_id]))
          else
            @bread_crumbs.push BreadCrumb.new("Past submissions", archives_author_center_index_path)
            @bread_crumbs.push BreadCrumb.new("\##{@submission.id}", archives_author_center_index_path)
          end
        else
          #@bread_crumbs.push BreadCrumb.new("Review", submissions_path) unless action_name == 'index'
          @bread_crumbs.push BreadCrumb.new("Submission \##{@submission.id}", submission_path(@submission)) if params[:submission_id]
          @bread_crumbs.push BreadCrumb.new("Submission \##{@submission.id}", author_center_index_path) if params[:author_center_id]
        end
        @bread_crumbs.push BreadCrumb.new("Referee #{RefereeAssignment.find(params[:id]).referee_letter}", submission_referee_assignment_path(params[:id]))
      elsif action_name == 'edit_due_date'
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:submission_id]}", submission_path(params[:submission_id]))
        @bread_crumbs.push BreadCrumb.new("Referee #{RefereeAssignment.find(params[:id]).referee_letter}", submission_referee_assignment_path(params[:submission_id], params[:id]))
        @bread_crumbs.push BreadCrumb.new('Edit due date', '#')
      elsif action_name == 'edit_report'
        @bread_crumbs.push BreadCrumb.new("Submission \##{params[:submission_id]}", submission_path(params[:submission_id]))
        @bread_crumbs.push BreadCrumb.new("Referee #{RefereeAssignment.find(params[:id]).referee_letter}", submission_referee_assignment_path(params[:submission_id], params[:id]))
        @bread_crumbs.push BreadCrumb.new('Edit report', '#')
      end
    end

    # EMAILS
    if controller_name == 'sent_emails'
      #@bread_crumbs.push BreadCrumb.new('Review', submissions_path)
      @submission = Submission.find(params[:submission_id]) if params[:submission_id]
      @submission = Submission.find(params[:archive_id]) if params[:archive_id]

      if params[:archive_id]
        @bread_crumbs.push BreadCrumb.new("Archives", archives_path)
        @bread_crumbs.push BreadCrumb.new("Submission \##{@submission.id}", archive_path(@submission))
      else
        @bread_crumbs.push BreadCrumb.new("Submission \##{@submission.id}", submission_path(@submission))
      end

      @referee_assignment = RefereeAssignment.find(params[:referee_assignment_id]) if params[:referee_assignment_id]
      if @referee_assignment
        if params[:archive_id]
          #@bread_crumbs.push BreadCrumb.new("Referee #{RefereeAssignment.find(params[:referee_assignment_id]).referee_letter}", archive_referee_assignment_path(@submission, @referee_assignment))
          @bread_crumbs.push BreadCrumb.new("Sent Emails", archive_referee_assignment_sent_emails_path(@submission, @referee_assignment))
        else
          #@bread_crumbs.push BreadCrumb.new("Referee #{RefereeAssignment.find(params[:referee_assignment_id]).referee_letter}", submission_referee_assignment_path(@submission, @referee_assignment))
          @bread_crumbs.push BreadCrumb.new("Sent Emails", submission_referee_assignment_sent_emails_path(@submission, @referee_assignment))
        end
      else
        if params[:archive_id]
          @bread_crumbs.push BreadCrumb.new("Sent Emails", archive_sent_emails_path(@submission))
        else
          @bread_crumbs.push BreadCrumb.new("Sent Emails", submission_sent_emails_path(@submission))
        end
      end

      if action_name == 'show'
        @bread_crumbs.push BreadCrumb.new("##{params[:id]}", submission_sent_emails_path(@submission))
      end
    end

    # JOURNAL SETTINGS
    if controller_name == 'journal_settings'
      if action_name == 'show'
        #@bread_crumbs.push BreadCrumb.new("Settings", edit_journal_setting_path(params[:id]))
      elsif action_name.in? ['edit', 'update', 'create_area', 'remove_area']
        #@bread_crumbs.push BreadCrumb.new("Settings", edit_journal_setting_path(params[:id]))
        #@bread_crumbs.push BreadCrumb.new("Edit", edit_user_path(params[:id]))
      elsif action_name == 'show_email_template'
        @bread_crumbs.push BreadCrumb.new("Settings", edit_journal_setting_path)
        @bread_crumbs.push BreadCrumb.new("View template", '')
      end
    end

    # EMAIL TEMPLATES
    if controller_name == 'email_templates'
      #@bread_crumbs.push BreadCrumb.new('Settings', journal_settings_path)
      if action_name.in? ['show', 'update']
        @bread_crumbs.push BreadCrumb.new("Email Template: " + EmailTemplate.find(params[:id]).description, email_template_path(params[:id]))
      elsif action_name == 'edit'
        @bread_crumbs.push BreadCrumb.new("Email Template: " + EmailTemplate.find(params[:id]).description, email_template_path(params[:id]))
        @bread_crumbs.push BreadCrumb.new('Edit', edit_email_template_path(params[:id]))
      end
    end

    # AUTHOR_CENTER
    if controller_name == 'author_center'
      #@bread_crumbs.push BreadCrumb.new("Author", author_center_index_path) unless action_name == 'index'
      if action_name == 'archives'
        @bread_crumbs.push BreadCrumb.new("Past submissions", archives_author_center_index_path)
      elsif action_name == 'new' || action_name == 'create'
        @bread_crumbs.push BreadCrumb.new("New submission", new_author_center_path)
      end
    end

    # REFEREE_CENTER
    if controller_name == 'referee_center'
      @referee_assignment = RefereeAssignment.find(params[:id]) if params[:id]
      @submission = @referee_assignment.submission if @referee_assignment

      #@bread_crumbs.push BreadCrumb.new("Referee", referee_center_index_path) unless action_name == 'index'

      if action_name == 'edit_response' || action_name == 'update_response'
        @bread_crumbs.push BreadCrumb.new("Referee request", referee_center_index_path)
        @bread_crumbs.push BreadCrumb.new("Accept/decline", edit_response_referee_center_path(params[:id]))
      elsif action_name == 'edit_report' || action_name == 'update_report'
        @bread_crumbs.push BreadCrumb.new("Referee request", referee_center_index_path)
        @bread_crumbs.push BreadCrumb.new("Submit report", edit_report_referee_center_path(params[:id]))
      elsif action_name == "archives"
          @bread_crumbs.push BreadCrumb.new("Previous assignments", archives_referee_center_index_path)
      elsif action_name == "show"
          @bread_crumbs.push BreadCrumb.new("Previous assignments", archives_referee_center_index_path)
          @bread_crumbs.push BreadCrumb.new("Submission \##{@submission.id}", referee_center_path(params[:id]))
      end
    end

    if controller_name == 'one_click_reviews'
      if action_name == 'decline'
        @referee_assignment = RefereeAssignment.find_by_auth_token(params[:id])
        @bread_crumbs.push BreadCrumb.new("Referee request", referee_center_index_path)
        @bread_crumbs.push BreadCrumb.new("Suggest alternates", decline_one_click_review_path(params[:id]))
      end
    end
  end

end
