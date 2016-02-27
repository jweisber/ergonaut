require 'spec_helper'

describe "Statistics pages" do

  describe "index page" do
    before { visit statistics_path }

    it "redirects to the show page for the current year" do
      expect(current_path).to eq(statistic_path(Time.now.year))
    end
  end

  describe "show page for current year" do
    before do
      create(:managing_editor)

      2.times do
        create(:submission)
      end
      2.times do
        s = create(:desk_rejected_submission)
        s.update_attributes(decision_entered_at: 5.days.from_now)
        s.author.update_attributes(gender: 'Male')
      end
      2.times do
        s = create(:rejected_after_review_submission)
        s.update_attributes(decision_entered_at: 10.days.from_now)
        s.author.update_attributes(gender: 'Female')
      end
      2.times do
        s = create(:first_revision_submission_minor_revisions_requested)
        s.original.update_attributes(decision_entered_at: 15.days.from_now)
        s.update_attributes(decision: Decision::ACCEPT)
        s.update_attributes(decision_entered_at: 20.days.from_now)
      end
      2.times do
        s = create(:first_revision_submission_minor_revisions_requested)
        s.original.update_attributes(decision_entered_at: 25.days.from_now)
        s.update_attributes(decision: Decision::REJECT)
        s.update_attributes(decision_entered_at: 30.days.from_now)
      end
      2.times do
        s = create(:accepted_submission)
        s.update_attributes(decision_entered_at: 35.days.from_now)
        s.author.update_attributes(gender: 'Female')
      end

      visit statistic_path(Time.now.year)
    end

    it "has links to pages for previous years" do
      for year in 2013..(Time.now.year-1) do
        expect(page).to have_link(year, href: statistic_path(year))
      end
    end

    it "loads the statistics for first-round decisions" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[0][0]).to match(/"Desk reject":2/)
      expect(chart_scripts[0][0]).to match(/"Reject after external review":2/)
      expect(chart_scripts[0][0]).to match(/"Major revisions":4/)
      expect(chart_scripts[0][0]).to match(/"Minor revisions":0/)
      expect(chart_scripts[0][0]).to match(/"Accept":2/)
    end

    it "loads the statistics for second-round decisions" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[1][0]).to match(/"Accept":2/)
      expect(chart_scripts[1][0]).to match(/"Reject":2/)
    end

    it "loads the statistics for average times to a decision" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[2][0]).to match(/"All submissions":20/)
      expect(chart_scripts[2][0]).to match(/"Desk rejections":5/)
      expect(chart_scripts[2][0]).to match(/"Externally reviewed":21/)
      expect(chart_scripts[2][0]).to match(/"Resubmissions":25/)
    end

    it "loads the statistics for authors by gender" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[3][0]).to match(/"Female":4/)
      expect(chart_scripts[3][0]).to match(/"Male":2/)
      expect(chart_scripts[3][0]).to match(/"Unknown":4/)
    end

    it "loads the statistics for submissions by area" do
      chart_scripts = page.html.scan(/<script type="text\/javascript">(.*?)<\/script>/m)

      expect(chart_scripts[4][0]).to match(/"Ar\. \d* ":1/)
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
      for year in 2013..Time.now.year do
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
      for year in 2014..Time.now.year do
        expect(page).to have_link(year.to_s, href: statistic_path(year)) unless year == 2013
      end
    end
  end

end
