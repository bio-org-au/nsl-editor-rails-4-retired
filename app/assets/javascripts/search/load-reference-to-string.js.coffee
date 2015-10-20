
window.loadReferenceToString = (fields) ->
  console.log("loadReferenceFields")
  settings = getSettings()
  fields =  _.reduce(fieldMap,appendOneField,'')
  assertions = getAssertions()
  $('#query-string-field').val("#{settings}#{fields}#{assertions}")

fieldMap =
  'ref-advanced-search-citation' : ''
  'ref-advanced-search-type' : 'type:'
  'ref-advanced-search-author' : 'author:'
  'ref-advanced-search-year' : 'year:'
  'ref-advanced-search-parent-citation' : 'parent-citation:'
  'ref-advanced-search-parent-title' : 'parent-title:'
  'ref-advanced-search-comments' : 'comments:'
  'ref-advanced-search-comments-by' : 'comments-by:'

getSettings = ->
  listOrCount = $('#ref-advanced-search-list-or-count').val()
  if listOrCount.match(/count/)
    'count ref'
  else
    "#{$('#ref-advanced-search-set-size').val()} ref"

getAssertions = ->
  str = ''
  $('.ref-search-assertion:checked').map( ->
    str += ' ' + this.value + ' ')
  str

appendOneField = (memo,searchToken,fieldId,list) ->
  if $('#'+fieldId).val().length > 0
    if searchToken.length == 0
      "#{memo} #{$('#'+fieldId).val()}"
    else
      "#{memo} #{searchToken} #{$('#'+fieldId).val()}"
  else
    memo


