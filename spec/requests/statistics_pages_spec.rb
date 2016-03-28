require 'spec_helper'

describe "Statistics pages" do

  let(:area_editor) { create(:area_editor) }

  describe "index page" do
    before { visit statistics_path }

    it "redirects to the show page for the current year" do
      expect(current_path).to match(/last_12_months/)
    end
  end

  shared_examples "ordinary public stats page" do
    describe "show page for previous calendar year" do
      before { visit statistic_path("2010") }

      it "loads the statistics for first-round decisions" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[0][0]).to match(/"Desk reject":1/)
        expect(chart_scripts[0][0]).to match(/"Reject after external review":1/)
        expect(chart_scripts[0][0]).to match(/"Major revisions":2/)
        expect(chart_scripts[0][0]).to match(/"Minor revisions":0/)
        expect(chart_scripts[0][0]).to match(/"Accept":0/)
      end

      it "loads the statistics for second-round decisions" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[1][0]).to match(/"Accept":0/)
        expect(chart_scripts[1][0]).to match(/"Reject":2/)
      end

      it "loads the statistics for average times to a decision" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[2][0]).to match(/"All submissions":31/)
        expect(chart_scripts[2][0]).to match(/"Desk rejections":31/)
        expect(chart_scripts[2][0]).to match(/"Externally reviewed":31/)
        expect(chart_scripts[2][0]).to match(/"Resubmissions":30/)
      end

      it "loads the statistics for authors by gender" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[3][0]).to match(/"Female":2/)
        expect(chart_scripts[3][0]).to match(/"Male":2/)
        expect(chart_scripts[3][0]).to match(/"Unknown":0/)
      end

      it "loads the statistics for submissions by area" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[4][0]).to match(/"Ar\. \d* ":1/)
      end
    end

    it "has links to pages for previous years" do
      for year in 2013..(Time.now.year-1) do
        expect(page).to have_link(year, href: statistic_path(year))
      end
    end

    it "loads the statistics for first-round decisions" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[0][0]).to match(/"Desk reject":1/)
      expect(chart_scripts[0][0]).to match(/"Reject after external review":1/)
      expect(chart_scripts[0][0]).to match(/"Major revisions":1/)
      expect(chart_scripts[0][0]).to match(/"Minor revisions":1/)
      expect(chart_scripts[0][0]).to match(/"Accept":1/)
    end

    it "loads the statistics for second-round decisions" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[1][0]).to match(/"Accept":1/)
      expect(chart_scripts[1][0]).to match(/"Reject":1/)
    end

    it "loads the statistics for average times to a decision" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[2][0]).to match(/"All submissions":34/)
      expect(chart_scripts[2][0]).to match(/"Desk rejections":30/)
      expect(chart_scripts[2][0]).to match(/"Externally reviewed":38/)
      expect(chart_scripts[2][0]).to match(/"Resubmissions":31/)
    end

    it "loads the statistics for authors by gender" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[3][0]).to match(/"Female":2/)
      expect(chart_scripts[3][0]).to match(/"Male":3/)
      expect(chart_scripts[3][0]).to match(/"Unknown":0/)
    end

    it "loads the statistics for submissions by area" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[4][0]).to match(/"Ar\. \d* ":1/)
    end
  end

  describe "show page for the last 12 months" do
    before do
      create(:managing_editor)

      create(:submission, created_at: 11.months.ago)

      new_years_2010 = DateTime.new(2010)

      s = create(:desk_rejected_submission,
                 area_editor: area_editor,
                 created_at: new_years_2010,
                 decision_entered_at: new_years_2010 + 1.month)
      s.author.update_attributes(gender: 'Male')

      s = create(:desk_rejected_submission,
                 area_editor: area_editor,
                 created_at: 11.months.ago,
                 decision_entered_at: 10.months.ago)
      s.author.update_attributes(gender: 'Male')

      s = create(:rejected_after_review_submission,
                 created_at: new_years_2010,
                 decision_entered_at: new_years_2010 + 1.month)
      s.author.update_attributes(gender: 'Female')

      s = create(:rejected_after_review_submission,
                 created_at: 11.months.ago,
                 decision_entered_at: 10.months.ago)
      s.author.update_attributes(gender: 'Female')

      s = create(:first_revision_submission,
                 area_editor: area_editor,
                 decision: Decision::REJECT,
                 created_at: 11.months.ago,
                 decision_entered_at: 10.months.ago,
                 decision_approved: true)
      s.original.update_attributes(area_editor: area_editor)
      s.original.update_attributes(created_at: new_years_2010, decision_entered_at: new_years_2010 + 1.month)
      s.author.update_attributes(gender: 'Male')

      s = create(:first_revision_submission,
                 decision: Decision::ACCEPT,
                 created_at: 7.months.ago,
                 decision_entered_at: 6.months.ago,
                 decision_approved: true)
      s.original.update_attributes(created_at: 11.months.ago, decision_entered_at: 10.months.ago)
      s.author.update_attributes(gender: 'Male')

      s = create(:first_revision_submission,
                 decision: Decision::REJECT,
                 created_at: 11.months.ago,
                 decision_entered_at: 10.months.ago,
                 decision_approved: true)
      s.original.update_attributes(area_editor: area_editor, decision: Decision::MAJOR_REVISIONS)
      s.original.update_attributes(created_at: new_years_2010, decision_entered_at: new_years_2010 + 1.month)
      s.author.update_attributes(gender: 'Female')

      s = create(:first_revision_submission,
                 area_editor: area_editor,
                 created_at: 7.months.ago,
                 decision_entered_at: 6.months.ago,
                 decision: Decision::REJECT,
                 decision_approved: true)
      s.original.update_attributes(area_editor: area_editor, decision: Decision::MINOR_REVISIONS)
      s.original.update_attributes(created_at: 11.months.ago, decision_entered_at: 9.months.ago)
      s.author.update_attributes(gender: 'Female')

      s = create(:accepted_submission, created_at: 5.months.ago)
      s.update_attributes(decision_entered_at: 4.months.ago)
      s.author.update_attributes(gender: 'Male')

      visit statistics_path
    end

    context "when not logged in" do
      it_should_behave_like "ordinary public stats page"
    end

    context "when logged in as an author" do
      before do
        valid_sign_in(create(:author))
        visit statistics_path
      end

      it_should_behave_like "ordinary public stats page"
    end

    context "when logged in as a managing editor" do
      before do
        managing_editor = User.where(managing_editor: true).first
        valid_sign_in(managing_editor)
        visit statistics_path
      end

      it_should_behave_like "ordinary public stats page"
    end

    context "when logged in as an area editor" do
      before do
        valid_sign_in(area_editor)
        visit statistics_path
      end

      it "has links to pages for previous years" do
        for year in 2013..(Time.now.year-1) do
          expect(page).to have_link(year, href: statistic_path(year))
        end
      end

      it "loads overall first-round decision stats" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[0][0]).to match(/First round decisions/)
        expect(chart_scripts[0][0]).to match(/"Desk reject":1/)
        expect(chart_scripts[0][0]).to match(/"Reject after external review":1/)
        expect(chart_scripts[0][0]).to match(/"Major revisions":1/)
        expect(chart_scripts[0][0]).to match(/"Minor revisions":1/)
        expect(chart_scripts[0][0]).to match(/"Accept":1/)
      end

      it "loads personal first-round decision stats" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[1][0]).to match(/My first round decisions/)
        expect(chart_scripts[1][0]).to match(/"Desk reject":1/)
        expect(chart_scripts[1][0]).to match(/"Reject after external review":0/)
        expect(chart_scripts[1][0]).to match(/"Major revisions":0/)
        expect(chart_scripts[1][0]).to match(/"Minor revisions":1/)
        expect(chart_scripts[1][0]).to match(/"Accept":0/)
      end

      it "loads overall second-round decision stats" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[2][0]).to match(/Second round decisions/)
        expect(chart_scripts[2][0]).to match(/"Accept":1/)
        expect(chart_scripts[2][0]).to match(/"Reject":1/)
      end

      it "loads personal second-round decision stats" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[3][0]).to match(/My second round decisions/)
        expect(chart_scripts[3][0]).to match(/"Accept":0/)
        expect(chart_scripts[3][0]).to match(/"Reject":1/)
      end

      it "loads overall time-to-decision stats" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[4][0]).to match(/Average days to decision/)
        expect(chart_scripts[4][0]).to match(/"All submissions":34/)
        expect(chart_scripts[4][0]).to match(/"Desk rejections":30/)
        expect(chart_scripts[4][0]).to match(/"Externally reviewed":38/)
        expect(chart_scripts[4][0]).to match(/"Resubmissions":31/)
      end

      it "loads personal time-to-decision stats" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[5][0]).to match(/My average days to decision/)
        expect(chart_scripts[5][0]).to match(/"All submissions":38/)
        expect(chart_scripts[5][0]).to match(/"Desk rejections":30/)
        expect(chart_scripts[5][0]).to match(/"Externally reviewed":61/)
        expect(chart_scripts[5][0]).to match(/"Resubmissions":31/)
      end

      it "loads the statistics for authors by gender" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[6][0]).to match(/"Female":2/)
        expect(chart_scripts[6][0]).to match(/"Male":3/)
        expect(chart_scripts[6][0]).to match(/"Unknown":0/)
      end

      it "loads the statistics for submissions by area" do
        chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

        expect(chart_scripts[7][0]).to match(/"Ar\. \d* ":1/)
      end
    end
  end

  describe "show page for 2014" do
    before { visit statistic_path(2014) }

    it "shows the statistics for 2014", js: true do
      expect(page).to have_content("29.5%")
      expect(page).to have_content("59.1%")
      expect(page).to have_content("20%")
      expect(page).to have_content("80%")
      expect(page).to have_content("83.6%")
    end

    it "has links for 2013 up through the current year" do
      for year in 2013..(Time.now.year-1) do
        expect(page).to have_link(year.to_s, href: statistic_path(year)) unless year == 2014
      end
    end
  end

  describe "show page for 2013" do
    before { visit statistic_path(2013) }

    it "shows the statistics for 2014", js: true do
      expect(page).to have_content("29.1%")
      expect(page).to have_content("63.1%")
      expect(page).to have_content("100%")
    end

    it "has links for 2014 up through the current year" do
      for year in 2014..(Time.now.year - 1) do
        expect(page).to have_link(year.to_s, href: statistic_path(year)) unless year == 2013
      end
    end
  end

end
