# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


jQuery ->
	users = []
	map = {}
	$(".user-fuzzy-search").typeahead
		source: (query, process) ->
			$.post '/users/fuzzy_search',
			  query: query
			, (data) ->
			    map = data
			    users = []
			    for description,id of data
			      users.push(description)
			    process users
			, 'json'
			return null
		updater: (item) ->
			$('#existing_user_id').val(map[item])
			$('#user_search_form').attr('action', '/users/' + map[item])
			item
		matcher: (item) ->
		 	return true

jQuery ->
	if $('#javascript_delayed_alert_hook').length > 0
		text = $('#javascript_delayed_alert_hook').val()
		setTimeout( ->
			alert(text)
		, 500)

jQuery ->
	$('#due-date-picker').datepicker({ autoclose: true })
