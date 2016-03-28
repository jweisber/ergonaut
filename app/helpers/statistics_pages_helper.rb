module StatisticsPagesHelper

  def first_round_decisions_chart_title(area_editor = nil)

  	if area_editor
  		title = "My first round decisions: #{@ae_decided}"
  		if @ae_withdrawn > 0
	    	title += " (and #{@ae_withdrawn} withdrawn)"
	    else
	    	title
	    end
  	else
  		title = "First round decisions: #{@decided}"
  		if @withdrawn > 0
	    	title += " (and #{@withdrawn} withdrawn)"
	    else
	    	title
	    end
  	end
  end

  def show_area_editor_stats
    current_user &&
    current_user.area_editor? &&
    (@year > 2014 || @year == "last_12_months".to_i)
  end
end
