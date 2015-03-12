class Decision
  def Decision.add_item(key,value)
    @hash ||= {}
    @hash[key]=value
  end
  
  def Decision.const_missing(key)
    if @hash[key]
      @hash[key]
    else
      raise "Decision: no such decision: #{key}"
    end
  end
  
  def Decision.each
    @hash.each {|key,value| yield(key,value)}
  end
  
  def Decision.values
      @hash.values || []
  end

  def Decision.keys
    @hash.keys || []
  end
  
  def Decision.all
    Decision.values
  end
  
  def Decision.all_recommendations
    Decision.values.delete_if { |value| value == Decision::NO_DECISION }
  end
  
  def Decision.disabled(submission)
    if submission.revision_number > 0
      [Decision::MAJOR_REVISIONS, Decision::MINOR_REVISIONS]
    end
  end

  def Decision.[](key)
    if @hash[key]
      @hash[key]
    else
      raise "Decision: no such decision: #{key}"
    end
  end
  
  Decision.add_item :NO_DECISION, 'No Decision'
  Decision.add_item :REJECT, 'Reject'
  Decision.add_item :MAJOR_REVISIONS, 'Major Revisions'
  Decision.add_item :MINOR_REVISIONS, 'Minor Revisions'
  Decision.add_item :ACCEPT, 'Accept'
end