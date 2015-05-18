module StatisticsPagesHelper
  
  def first_round_decisions_chart_title
    title = "First round decisions: #{@decided}"
    if @withdrawn > 0 
      title += " (and #{@withdrawn} withdrawn)"
    else
      title
    end
  end
  
end
