class StatisticsController < ApplicationController

  skip_before_filter :signed_in_user
  before_filter :add_scopes, :set_annual_corrections

  def index
    redirect_to statistic_path(Time.now.year)
  end

  def show
    @year = params[:id].to_i

    @decided = Submission.year_submitted(@year).with_decision.count
    @decided += @corrections[@year][:decided].to_i
    @withdrawn = Submission.year_submitted(@year).where(withdrawn: true).count
    @withdrawn += @corrections[@year][:withdrawn].to_i

    @reject = Submission.original
                        .year_submitted(@year)
                        .with_decision.where(decision: Decision::REJECT).count
    @reject += @corrections[@year][:reject].to_i
    @reject_after_review = Submission.original
                                     .year_submitted(@year)
                                     .with_decision
                                     .where(decision: Decision::REJECT)
                                     .externally_reviewed
                                     .count
    @reject_after_review += @corrections[@year][:reject_after_review].to_i
    @desk_reject = @reject - @reject_after_review
    @major_revisions = Submission.original
                                 .year_submitted(@year)
                                 .with_decision
                                 .where(decision: Decision::MAJOR_REVISIONS)
                                 .count
    @major_revisions += @corrections[@year][:major_revisions].to_i
    @minor_revisions = Submission.original
                                 .year_submitted(@year)
                                 .with_decision
                                 .where(decision: Decision::MINOR_REVISIONS)
                                 .count
    @minor_revisions += @corrections[@year][:minor_revisions].to_i
    @accept = Submission.original
                        .year_submitted(@year)
                        .with_decision.where(decision: Decision::ACCEPT).count
    @accept += @corrections[@year][:accept].to_i

    @resubmissions_rejected = Submission.resubmission
                                     .year_originally_submitted(@year)
                                     .with_decision
                                     .where(decision: Decision::REJECT)
                                     .count
    @resubmissions_rejected += @corrections[@year][:resubmissions_rejected].to_i
    @resubmissions_accepted = Submission.resubmission
                                     .year_originally_submitted(@year)
                                     .with_decision
                                     .where(decision: Decision::ACCEPT)
                                     .count
    @resubmissions_accepted += @corrections[@year][:resubmissions_accepted].to_i
    @resubmissions = @resubmissions_rejected + @resubmissions_accepted

    @areas_hash = Hash.new
    Area.active_ordered_by_name.each do |area|
      @areas_hash[area.short_name] = Submission.original
                                               .year_submitted(@year)
                                               .with_decision
                                               .in_area(area.name)
                                               .count
      @areas_hash[area.short_name] += @corrections[@year][area.name].to_i
    end

    submissions = Submission.select(:decision_entered_at)
                            .select(:created_at)
                            .year_submitted(@year)
                            .with_decision
    average_ttd_overall = average_ttd(submissions,
                                      @corrections[@year][:overall_numerator],
                                      @corrections[@year][:overall_denominator])

    submissions = Submission.select(:id)
                            .select(:decision_entered_at)
                            .select(:created_at)
                            .original                            
                            .year_submitted(@year)
                            .with_decision
                            .not_externally_reviewed
    average_ttd_desk_rejections = average_ttd(submissions,
                              @corrections[@year][:desk_rejections_numerator],
                              @corrections[@year][:desk_rejections_denominator])

    submissions = Submission.select(:decision_entered_at)
                            .select(:created_at)
                            .original
                            .year_submitted(@year)
                            .with_decision
                            .externally_reviewed
    average_ttd_external_review = average_ttd(submissions,
                              @corrections[@year][:external_review_numerator],
                              @corrections[@year][:external_review_denominator])

    submissions = Submission.select('submissions.decision_entered_at')
                            .select('submissions.created_at')
                            .resubmission
                            .year_originally_submitted(@year)
                            .with_decision
    average_ttd_resubmissions = average_ttd(submissions,
                                              @corrections[@year][:resubmissions_numerator],
                                              @corrections[@year][:resubmissions_denominator])

    @ttd_hash = { "All submissions" => average_ttd_overall,
                  "Desk rejections" => average_ttd_desk_rejections,
                  "Externally reviewed" => average_ttd_external_review,
                  "Resubmissions" => average_ttd_resubmissions }

    @genders_hash = { 'Male' => @corrections[@year][:male_authors],
                      'Female' => @corrections[@year][:female_authors] }
  end


  private

    def add_scopes
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
          where("submissions.created_at >= ? AND submissions.created_at < ?", DateTime.new(year), DateTime.new(year+1))
        end

        scope :year_originally_submitted, ->(year) do
          joins('LEFT OUTER JOIN submissions originals ON submissions.original_id = originals.id')
          .where("originals.created_at >= ? AND originals.created_at < ?",
                 DateTime.new(year),
                 DateTime.new(year+1))
        end

        scope :original, -> do
          where('submissions.revision_number = 0')
        end

        scope :resubmission, -> do
          where('submissions.revision_number > 0')
        end
      end
    end

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
          :resubmissions_accepted => 14,
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
          :overall_numerator => 6073,
          :overall_denominator => 234,
          :desk_rejections_numerator => 1368,
          :desk_rejections_denominator => 131,
          :external_review_numerator => 4215,
          :external_review_denominator => 86,
          :resubmissions_numerator => 490,
          :resubmissions_denominator => 18
        },
        2015 => {
          :decided => 18,
          :withdrawn => 0,
          :reject => 16,
          :reject_after_review => 4,
          :major_revisions => 2,
          :minor_revisions => 0,
          :accept => 0,
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
          :overall_numerator => 470,
          :overall_denominator => 18,
          :desk_rejections_numerator => 127,
          :desk_rejections_denominator => 13,
          :external_review_numerator => 343,
          :external_review_denominator => 6,
          :resubmissions_numerator => 0,
          :resubmissions_denominator => 0
        }
      }
      @corrections[2015] = {} if Rails.env.test?
    end

    def ttd(submission)
      (submission.decision_entered_at.to_date - submission.created_at.to_date).to_i
    end

    def average_ttd(submissions, numerator_correction, denominator_correction)
      total_days = submissions.inject(0) { |sum, s| sum + ttd(s) }
      total_days += numerator_correction.to_i
      if total_days > 0
        (total_days.to_f / (submissions.size + denominator_correction.to_i)).round
      else
        0
      end
    end
end