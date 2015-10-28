
window.loadAuthorToString = (fields) ->
  console.log("loadAuthorFields")
  listCount = getListCount()
  fields = _.reduce(fieldMap,appendOneField,'')
  assertions = getAssertions()
  $('#query-string-field').val("#{listCount}#{fields}#{assertions}")
  $('#query-target').val("Authors")

fieldMap =
  'author-advanced-search-name' : ''
  'author-advanced-search-abbrev' : 'abbrev:'
  'author-advanced-search-full-name' : 'full-name:'
  'author-advanced-search-ipni-id' : 'ipni-id:'
  'author-advanced-search-comments' : 'comments:'
  'author-advanced-search-comments-by' : 'comments-by:'

getListCount = ->
  listOrCount = $('#author-advanced-search-list-or-count').val()
  if listOrCount.match(/count/)
    'count '
  else
    "limit:#{$('#author-advanced-search-set-size').val()} "

getAssertions = ->
  str = ''
  $('.author-search-assertion:checked').map( ->
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


