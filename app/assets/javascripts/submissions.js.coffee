# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# confirm before submitting
jQuery ->
  $("#submitBtn").click (event) ->
    decision = $("#submission_decision option:selected").text()
    if decision != "No Decision"
      confirm "#{JournalSettings.current.number_of_reports_expected} referee reports are usually required once a manuscript has been sent out for external review. Do you want to enter a decision anyway?"


# tooltips
jQuery ->			
	$("a[data-toggle]").tooltip({ placement: 'top'})


# popovers
jQuery ->
  $('.popover-link').popover(
    html : true, 
    placement : $('.popover-link').attr('placement')
  )
  $('.popover-link').on( 'click', (e) ->
			e.preventDefault()
			return true
  )

# popovers: hide on outside-click
jQuery ->
  $(':not(#anything)').on('click', (e) ->
    $('.popover-link').each( ->
      if (!$(this).is(e.target) && $(this).has(e.target).length == 0 && $('.popover').has(e.target).length == 0)
        $(this).popover('hide')
    )
  )