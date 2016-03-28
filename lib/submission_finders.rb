module SubmissionFinders

  Submission.class_eval do
    scope :active, -> { where(archived: false, withdrawn: false) }
    scope :undecided, -> { where("decision = ?", Decision::NO_DECISION) }
    scope :not_sent_out_for_review, -> { where('submissions.id NOT IN (SELECT submission_id FROM referee_assignments WHERE canceled != ?)', true) }
    scope :internal_review_deadline_passed, -> { where('area_editor_assignments.updated_at < ?', Time.current - JournalSettings.current.days_for_initial_review.days) }
    scope :no_email_with_action, ->(action) { where('submissions.id NOT IN (SELECT submission_id FROM sent_emails WHERE action = ?)', action) }
    scope :no_email_with_action_for_n_days, ->(action, n) { where('submissions.id NOT IN (SELECT submission_id FROM sent_emails WHERE action = ? AND created_at > ?)', action, n.days.ago) }
  end

  def internal_review_reminder_needed
    self.joins(:area_editor_assignment).uniq
        .active
        .undecided
        .not_sent_out_for_review
        .internal_review_deadline_passed
        .no_email_with_action_for_n_days(:remind_ae_internal_review_overdue, 3)
  end


  Submission.class_eval do
    scope :sent_out_for_review, -> { where('submissions.id IN (SELECT submission_id FROM referee_assignments WHERE canceled != ?)', true) }
    scope :at_least_one_agreed_assignment, -> { where('EXISTS (SELECT 1 FROM referee_assignments AS ra WHERE submissions.id = ra.submission_id AND ra.agreed = ? AND ra.canceled = ?)', true, false) }
    scope :all_reports_completed, -> { where('NOT EXISTS (SELECT 1 FROM referee_assignments AS ra WHERE submissions.id = ra.submission_id AND (ra.agreed = ? OR ra.agreed IS NULL) AND ra.canceled = ? AND ra.report_completed = ?)', true, false, false) }
  end

  def area_editor_decision_based_on_external_reviews_overdue
    candidates = self.active
                     .undecided
                     .sent_out_for_review
                     .all_reports_completed
                     .no_email_with_action_for_n_days(:remind_ae_decision_based_on_external_reviews_overdue, 2)
    candidates.delete_if { |s| !s.area_editor_decision_based_on_external_review_overdue? }
  end


  Submission.class_eval do
    scope :no_area_editor, -> { where('area_editor_assignments.user_id IS NULL') }
    scope :area_editor_assignment_deadline_passed, -> { where('submissions.created_at < ?', Time.current - JournalSettings.current.days_to_assign_area_editor.days) }
  end

  def area_editor_assignment_reminder_needed
    self.active
        .joins('LEFT OUTER JOIN area_editor_assignments ON submissions.id = area_editor_assignments.submission_id')
        .no_area_editor
        .area_editor_assignment_deadline_passed
        .no_email_with_action_for_n_days(:remind_managing_editors_assignment_overdue, 1)
        .group('submissions.id')
  end


  Submission.class_eval do
    scope :decided, -> { where('submissions.decision != ?', Decision::NO_DECISION) }
    scope :decision_not_approved, -> { where(decision_approved: false) }
    scope :decision_approval_deadline_passed, -> { where('submissions.decision_entered_at < ?', Time.current - JournalSettings.current.days_to_remind_overdue_decision_approval.days) }
  end

  def decision_approval_reminder_needed
    self.active
        .decided
        .decision_not_approved
        .decision_approval_deadline_passed
        .no_email_with_action_for_n_days(:remind_managing_editors_decision_approval_overdue, 1)
  end

  Submission.class_eval do
    scope :with_decision, -> do
      where(decision_approved: true)
    end

    scope :externally_reviewed, -> do
      where('EXISTS (SELECT 1 FROM referee_assignments AS r WHERE submissions.id = r.submission_id AND r.report_completed = ?)', true)
    end

    scope :not_externally_reviewed, -> do
      where('NOT EXISTS (SELECT 1 FROM referee_assignments AS r WHERE submissions.id = r.submission_id AND r.report_completed = ?)', true)
    end

    scope :in_area, ->(area_name) do
      joins(:area)
      .uniq
      .where(areas: { name: area_name } )
    end

    scope :year_submitted, ->(year) do
      if year > 0
        start_date = DateTime.new(year)
      else
        start_date = DateTime.now - 1.year
      end
      where("submissions.created_at >= ? AND submissions.created_at < ?", start_date, start_date + 1.year)
    end

    scope :year_originally_submitted, ->(year) do
      if year > 0
        start_date = DateTime.new(year)
      else
        start_date = DateTime.now - 1.year
      end
      joins('LEFT OUTER JOIN submissions originals ON submissions.original_id = originals.id')
      .where("originals.created_at >= ? AND originals.created_at < ?",
             start_date,
             start_date + 1.year)
    end

    scope :original, -> do
      where('submissions.revision_number = 0')
    end

    scope :resubmission, -> do
      where('submissions.revision_number > 0')
    end

    scope :author_gender, ->(gender) do
      joins(:author)
      .uniq
      .where('users.gender = ?', gender)
    end

    scope :gender_unknown, -> do
      joins(:author)
      .uniq
      .where('users.gender IS NULL')
    end

    scope :area_editor, ->(area_editor) do
      if area_editor
        joins("INNER JOIN area_editor_assignments ON submissions.id = area_editor_assignments.submission_id")
        .where(area_editor_assignments: { user_id: area_editor.id })
      else
        nil
      end
    end
  end

end