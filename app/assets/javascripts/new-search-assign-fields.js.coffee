

window.assignFields = (fields) ->
  switch 
    when fields.target.match(/author/i)    then assignAuthorFields(fields)
    when fields.target.match(/name/i)      then assignNameFields(fields)
    when fields.target.match(/reference/i) then assignReferenceFields(fields)
    when fields.target.match(/instance/i)  then assignInstanceFields(fields)
    when fields.target.match(/tree/i)      then assignTreeFields(fields)
    else                                     assignNameFields(fields)

assignNameFields = (fields) ->
  $('a#advanced-search-tab-link-name').click()
  $('select#name-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#name-advanced-search-set-size').val(fields.setSize)
  $('#name-advanced-search-name').val(fields.term)
  
assignAuthorFields = (fields) ->
  $('a#advanced-search-tab-link-author').click()
  
assignInstanceFields = (fields) ->
  $('a#advanced-search-tab-link-instance').click()
  
assignReferenceFields = (fields) ->
  $('a#advanced-search-tab-link-reference').click()
  $('select#reference-advanced-search-list-or-count').val(fields.action.toLowerCase())
  
assignTreeFields = (fields) ->
  $('a#advanced-search-tab-link-tree').click()


