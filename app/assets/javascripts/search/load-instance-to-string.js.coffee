
window.loadInstanceToString = (fields) ->
  console.log("loadInstanceFields")
  listCount = getListCount()
  fields =  _.reduce(fieldMap,appendOneField,'')
  assertions = getAssertions()
  $('#query-string-field').val("#{listCount}#{fields}#{assertions}")
  $('#query-target').val("Instances")
  $('#search-target-button-text').text("Instances")

fieldMap =
  'instance-advanced-search-name' : ''
  'instance-advanced-search-type' : 'type:'
  'instance-advanced-search-page' : 'page:'
  'instance-advanced-search-page-qualifier' : 'page-qualifier:'
  'instance-advanced-search-comments' : 'adnot:'
  'instance-advanced-search-comments-by' : 'adnot-by:'
  'instance-advanced-search-notes' : 'notes:'
  'instance-advanced-search-note-key' : 'note-key:'

getListCount = ->
  listOrCount = $('#instance-advanced-search-list-or-count').val()
  if listOrCount.match(/count/)
    'count '
  else
    "limit:#{$('#instance-advanced-search-set-size').val()} "

getAssertions = ->
  str = ''
  $('.instance-search-assertion:checked').map( ->
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


