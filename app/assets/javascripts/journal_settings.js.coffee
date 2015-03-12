# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# Temporary hack to get a confirm-alert for the remove-area form, since confirm: isn't working on form submit buttons

jQuery -> 
	$('#remove-area-form').submit( (e) ->
		confirm("Are you sure you want to remove this area?")
	)