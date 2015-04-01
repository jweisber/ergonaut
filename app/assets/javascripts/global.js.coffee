# Work around a bug in IE 10/11: http://tinyurl.com/qykro7d
#   The bug makes a textarea's placeholder its value.
#   We undo that wherever it's happened.
jQuery ->
  $('textarea').each ->
    if $(this).val() == $(this).attr('placeholder')
      $(this).val ''