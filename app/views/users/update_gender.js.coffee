$("#spinner").hide();
$('#gender_popover_link').replaceWith('<%= j gender_popover_link(@user) %>');
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