

window.assignFields = (fields) ->
  switch 
    when fields.target.match(/^authors$/i)    then assignAuthorFields(fields)
    when fields.target.match(/^names$/i)      then assignNameFields(fields)
    when fields.target.match(/^references$/i) then assignReferenceFields(fields)
    when fields.target.match(/^instances$/i)  then assignInstanceFields(fields)
    when fields.target.match(/^tree$/i)      then assignTreeFields(fields)
    else                                     assignNameFields(fields)

assignNameFields = (fields) ->
  console.log("assignNameFields")
  $('a#advanced-search-tab-link-name').click()
  $('select#name-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#name-advanced-search-set-size').val(fields.setSize)
  $('#name-advanced-search-name').val(fields.term)
  _.each(fields.wherePairs,setFieldValue)
  setTypeOptions()

setFieldValue = (pair,key,list) ->
  console.log('setFieldValue start')
  canonicalField = canonicalizeField(pair.field)
  formField = fieldMap[canonicalField]
  canonicalValue = canonicalizeValue(canonicalField,pair.value)
  console.log("canonicalValue: #{canonicalValue}")
  $("##{formField}").val(canonicalValue)
  
setTypeOptions = ->
 $("select#name-advanced-search-name-type-options option").prop("selected", false)
 listVal = $("#name-advanced-search-name-type-list").val()
 console.log("listVal: #{listVal}")
 vals = listVal.split(',')
 _.each(vals,selectTypeOption)

selectTypeOption = (val,two,three) ->
  console.log("selectTypeOption: val: #{val}")
  $("select#name-advanced-search-name-type-options option[value='#{val.trim()}']").prop("selected", true)

canonicalizeField = (field) ->
  if canonMap.hasOwnProperty(field)
    canonMap[field]
  else
    field

canonicalizeValue = (field,value) ->
  if funMap.hasOwnProperty(field)
    functionName = funMap[field]
    fun = window[functionName];
    if typeof(fun) == "function"
      canonicalValue = fun(value);
    else
      throw "No such function: #{functionName}"
  else
    canonicalValue = value
  canonicalValue
 
window.nameRankerize = (value) ->
  console.log("nameRankerize for: #{value}")
  "name-rank: #{value.toLowerCase()}"
 
window.belowNameRankerize = (value) ->
  console.log("belowNameRankerize for: #{value}")
  "below-name-rank: #{value.toLowerCase()}"
 
window.aboveNameRankerize = (value) ->
  console.log("aboveNameRankerize for: #{value}")
  "above-name-rank: #{value.toLowerCase()}"
 
assignAuthorFields = (fields) ->
  $('a#advanced-search-tab-link-author').click()
  
assignInstanceFields = (fields) ->
  $('a#advanced-search-tab-link-instance').click()
  
assignReferenceFields = (fields) ->
  $('a#advanced-search-tab-link-reference').click()
  $('select#reference-advanced-search-list-or-count').val(fields.action.toLowerCase())
  
assignTreeFields = (fields) ->
  $('a#advanced-search-tab-link-tree').click()

canonMap =
  'nr:': 'name-rank:'
  'nt:': 'name-rank:'

fieldMap =
  'name-rank:': 'name_search_name_rank_id'
  'below-name-rank:': 'name_search_name_ranked_below'
  'above-name-rank:': 'name_search_name_ranked_above'
  'name-type:': 'name-advanced-search-name-type-list'
  'author-abbrev:': 'name-advanced-search-author-abbrev'
  'ex-author-abbrev:': 'name-advanced-search-ex-author-abbrev'
  'base-author-abbrev:': 'name-advanced-search-base-author-abbrev'
  'ex-base-author-abbrev:': 'name-advanced-search-ex-base-author-abbrev'
  'sanctioning-author-abbrev:': 'name-advanced-search-sanctioning-author-abbrev'
  'comments:': 'name-advanced-search-comments'
  'comments-by:': 'name-advanced-search-comments-by'

funMap =
  'name-rank:': 'nameRankerize'
  'below-name-rank:': 'belowNameRankerize'
  'above-name-rank:': 'aboveNameRankerize'





