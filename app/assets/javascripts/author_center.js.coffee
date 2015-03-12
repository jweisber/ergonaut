# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
	$( "#new_submission" ).submit( ( event ) ->
		form = this
		$("#uploading-modal").modal()
		event.preventDefault()
		setTimeout( ->
			form.submit()
		, 500)
	)