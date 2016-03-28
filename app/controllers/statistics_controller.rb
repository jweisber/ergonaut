class StatisticsController < ApplicationController

  skip_before_filter :signed_in_user
  before_filter :set_annual_corrections

  def index
    redirect_to statistic_path("last_12_months")
  end

  def show
    @year = params[:id].to_i
    @corrections[@year] = {} unless @corrections[@year]

    # DECISIONS
    # Submissions with Decisions
    arel = Submission.original.year_submitted(@year).with_decision
    @decided = arel.count
    @decided += @corrections[@year][:decided].to_i
    @ae_decided = area_editor_count(arel)

    # Withdrawn Submissions
    arel = Submission.year_submitted(@year).where(withdrawn: true)
    @withdrawn = arel.count
    @withdrawn += @corrections[@year][:withdrawn].to_i
    @ae_withdrawn = area_editor_count(arel)

    # Round 1: Rejected Submissions
    arel = Submission.original.year_submitted(@year).with_decision.where(decision: Decision::REJECT)
    @reject = arel.count
    @reject += @corrections[@year][:reject].to_i
    @ae_reject = area_editor_count(arel)

    # Round 1: Rejected After Review
    arel = Submission.original.year_submitted(@year).with_decision.where(decision: Decision::REJECT).externally_reviewed
    @reject_after_review = arel.count
    @reject_after_review += @corrections[@year][:reject_after_review].to_i
    @ae_reject_after_review = area_editor_count(arel)

    # Round 1: Desk Rejected
    @desk_reject = @reject - @reject_after_review
    @ae_desk_reject = @ae_reject - @ae_reject_after_review

    # Round 1: Major Revisions
    arel = Submission.original.year_submitted(@year).with_decision.where(decision: Decision::MAJOR_REVISIONS)
    @major_revisions = arel.count
    @major_revisions += @corrections[@year][:major_revisions].to_i
    @ae_major_revisions = area_editor_count(arel)

    # Round 1: Minor Revisions
    arel = Submission.original.year_submitted(@year).with_decision.where(decision: Decision::MINOR_REVISIONS)
    @minor_revisions = arel.count
    @minor_revisions += @corrections[@year][:minor_revisions].to_i
    @ae_minor_revisions = area_editor_count(arel)

    # Round 1: Accept
    arel = Submission.original.year_submitted(@year).with_decision.where(decision: Decision::ACCEPT)
    @accept = arel.count
    @accept += @corrections[@year][:accept].to_i
    @ae_accept = area_editor_count(arel)


    # Round 2: Reject
    arel = Submission.resubmission.year_originally_submitted(@year).with_decision.where(decision: Decision::REJECT)
    @resubmissions_rejected = arel.count
    @resubmissions_rejected += @corrections[@year][:resubmissions_rejected].to_i
    @ae_resubmissions_rejected = area_editor_count(arel)

    # Round 2: Accept
    arel = Submission.resubmission.year_originally_submitted(@year).with_decision.where(decision: Decision::ACCEPT)
    @resubmissions_accepted = arel.count
    @resubmissions_accepted += @corrections[@year][:resubmissions_accepted].to_i
    @ae_resubmissions_accepted = area_editor_count(arel)

    # Round 2: Total
    @resubmissions = @resubmissions_rejected + @resubmissions_accepted
    @ae_resubmissions = @ae_resubmissions_rejected + @ae_resubmissions_accepted


    # AREAS
    @areas_hash = Hash.new
    Area.active_ordered_by_name.each do |area|
      @areas_hash[area.short_name] = Submission.original.year_submitted(@year).with_decision.in_area(area.name).count
      @areas_hash[area.short_name] += @corrections[@year][area.name].to_i
    end


    # TIMES TO DECISION
    submissions = Submission.select('submissions.decision_entered_at').select('submissions.created_at').year_submitted(@year).with_decision
    average_ttd_overall = average_ttd(submissions, @corrections[@year][:overall_numerator], @corrections[@year][:overall_denominator])
    ae_average_ttd_overall = average_ttd(submissions.area_editor(current_user))

    submissions = Submission.select('submissions.id').select('submissions.decision_entered_at').select('submissions.created_at').original.year_submitted(@year).with_decision.not_externally_reviewed
    average_ttd_desk_rejections = average_ttd(submissions, @corrections[@year][:desk_rejections_numerator], @corrections[@year][:desk_rejections_denominator])
    ae_average_ttd_desk_rejections = average_ttd(submissions.area_editor(current_user))

    submissions = Submission.select('submissions.decision_entered_at').select('submissions.created_at').original.year_submitted(@year).with_decision.externally_reviewed
    average_ttd_external_review = average_ttd(submissions, @corrections[@year][:external_review_numerator], @corrections[@year][:external_review_denominator])
    ae_average_ttd_external_review = average_ttd(submissions.area_editor(current_user))

    submissions = Submission.select('submissions.decision_entered_at').select('submissions.created_at').resubmission.year_originally_submitted(@year).with_decision
    average_ttd_resubmissions = average_ttd(submissions, @corrections[@year][:resubmissions_numerator], @corrections[@year][:resubmissions_denominator])
    ae_average_ttd_resubmissions = average_ttd(submissions.area_editor(current_user))

    @ttd_hash = {
                  "All submissions" => average_ttd_overall,
                  "Desk rejections" => average_ttd_desk_rejections,
                  "Externally reviewed" => average_ttd_external_review,
                  "Resubmissions" => average_ttd_resubmissions
                }
    @ae_ttd_hash = {
                     "All submissions" => ae_average_ttd_overall,
                     "Desk rejections" => ae_average_ttd_desk_rejections,
                     "Externally reviewed" => ae_average_ttd_external_review,
                     "Resubmissions" => ae_average_ttd_resubmissions
                   }


    # GENDERS
    male_authors = Submission.year_submitted(@year).original.with_decision.author_gender('Male').count
    male_authors += @corrections[@year][:male_authors] if @corrections[@year][:male_authors]

    female_authors = Submission.year_submitted(@year).original.with_decision.author_gender('Female').count
    female_authors += @corrections[@year][:female_authors] if @corrections[@year][:female_authors]

    unknown_gender_authors = Submission.year_submitted(@year).original.with_decision.gender_unknown.count

    @genders_hash = { 'Male' => male_authors,
                      'Female' => female_authors,
                      'Unknown' => unknown_gender_authors }
  end


  private

    def set_annual_corrections
      @corrections = {
        2013 => {
          :decided => 141,
          :withdrawn => 0,
          :reject => 130,
          :reject_after_review => 41,
          :major_revisions => 7,
          :minor_revisions => 4,
          :accept => 0,
          :resubmissions_rejected => 0,
          :resubmissions_accepted => 9,
          :male_authors => 130,
          :female_authors => 15,
          'Continental Philosophy' => 7,
          'Epistemology' => 21,
          'Ethics' => 18,
          'Feminist Philosophy' =>	1,
          'History: Ancient Philosophy' => 2,
          'History: Medieval Philosophy' => 0,
          'History: Early Modern Philosophy' => 11,
          'History: Kant/post-Kant' => 5,
          'History: Logic' => 1,
          'Logic' => 3,
          'Metaphysics' => 18,
          'Not Listed' => 6,
          'Philosophy of Art' => 3,
          'Philosophy of Biology' => 3,
          'Philosophy of Language' => 9,
          'Philosophy of Mathematics' => 4,
          'Philosophy of Mind' => 13,
          'Philosophy of Physics' => 4,
          'Philosophy of Race' => 0,
          'Philosophy of Religion' => 0,
          'Philosophy of Science (General)' => 9,
          'Political Philosophy' => 3,
          :overall_numerator => 3530,
          :overall_denominator => 150,
          :desk_rejections_numerator => 726,
          :desk_rejections_denominator => 89,
          :external_review_numerator => 2450,
          :external_review_denominator => 52,
          :resubmissions_numerator => 354,
          :resubmissions_denominator => 9
        },
        2014 => {
          :decided => 216,
          :withdrawn => 0,
          :reject => 195,
          :reject_after_review => 65,
          :major_revisions => 15,
          :minor_revisions => 6,
          :accept => 4,
          :resubmissions_rejected => 4,
          :resubmissions_accepted => 16,
          :male_authors => 184,
          :female_authors => 36,
          'Continental Philosophy' => 11,
          'Epistemology' => 31,
          'Ethics' => 34,
          'Feminist Philosophy' =>	4,
          'History: Ancient Philosophy' => 5,
          'History: Medieval Philosophy' => 1,
          'History: Early Modern Philosophy' => 15,
          'History: Kant/post-Kant' => 8,
          'History: Logic' => 3,
          'Logic' => 7,
          'Metaphysics' => 17,
          'Not Listed' => 8,
          'Philosophy of Art' => 10,
          'Philosophy of Biology' => 1,
          'Philosophy of Language' => 12,
          'Philosophy of Mathematics' => 1,
          'Philosophy of Mind' => 19,
          'Philosophy of Physics' => 1,
          'Philosophy of Race' => 2,
          'Philosophy of Religion' => 5,
          'Philosophy of Science (General)' => 9,
          'Political Philosophy' => 12,
          :overall_numerator => 6129,
          :overall_denominator => 236,
          :desk_rejections_numerator => 1368,
          :desk_rejections_denominator => 131,
          :external_review_numerator => 4215,
          :external_review_denominator => 86,
          :resubmissions_numerator => 546,
          :resubmissions_denominator => 20
        },
        2015 => {
          :decided => 18,
          :withdrawn => 0,
          :reject => 16,
          :reject_after_review => 4,
          :major_revisions => 2,
          :minor_revisions => 0,
          :accept => 0,
          :resubmissions_rejected => 1,
          :resubmissions_accepted => 1,
          :male_authors => 17,
          :female_authors => 1,
          'Continental Philosophy' => 0,
          'Epistemology' => 4,
          'Ethics' => 2,
          'Feminist Philosophy' =>	0,
          'History: Ancient Philosophy' => 0,
          'History: Medieval Philosophy' => 0,
          'History: Early Modern Philosophy' => 0,
          'History: Kant/post-Kant' => 2,
          'History: Logic' => 1,
          'Logic' => 0,
          'Metaphysics' => 3,
          'Not Listed' => 1,
          'Philosophy of Art' => 0,
          'Philosophy of Biology' => 0,
          'Philosophy of Language' => 2,
          'Philosophy of Mathematics' => 0,
          'Philosophy of Mind' => 0,
          'Philosophy of Physics' => 0,
          'Philosophy of Race' => 0,
          'Philosophy of Religion' => 0,
          'Philosophy of Science (General)' => 1,
          'Political Philosophy' => 2,
          :overall_numerator => 566,
          :overall_denominator => 20,
          :desk_rejections_numerator => 127,
          :desk_rejections_denominator => 13,
          :external_review_numerator => 343,
          :external_review_denominator => 6,
          :resubmissions_numerator => 96,
          :resubmissions_denominator => 2
        }
      }
      @corrections[2016] = {} if Rails.env.test?
    end

    def area_editor_count(arel)
      if current_user && current_user.area_editor?
        arel.area_editor(current_user).count
      else
        0
      end
    end

    def ttd(submission)
      (submission.decision_entered_at.to_date - submission.created_at.to_date).to_i
    end

    def average_ttd(submissions, numerator_correction = 0, denominator_correction = 0)
      total_days = submissions.inject(0) { |sum, s| sum + ttd(s) }
      total_days += numerator_correction.to_i
      if total_days > 0
        (total_days.to_f / (submissions.size + denominator_correction.to_i)).round
      else
        0
      end
    end
end