# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# warn if approving "No Decision"
jQuery ->
  $(".edit_submission").submit (event) ->
    decision = $("#submission_decision").find(":selected").text()
    decision_approved = $("#submission_decision_approved").is(':checked')
    if decision == "No Decision" && decision_approved
      confirm "No decision has been entered. Are you sure you want to \"approve\" this \"decision\"?"


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
      $('form').on 'ajax:before', ->
        $('*').popover('hide')
        $('#spinner, #gender_popover_link').toggle()
        return true
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
