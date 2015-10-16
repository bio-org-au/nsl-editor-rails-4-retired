
window.assignReferenceFields = (fields) ->
  console.log("assignReferenceFields")
  $('a#advanced-search-tab-link-reference').click()
  $('select#ref-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#ref-advanced-search-set-size').val(fields.setSize)
  $('#ref-advanced-search-citation').val(fields.term)
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
  'c:': 'citation:'

fieldMap =
  'comments:': 'ref-advanced-search-comments'
  'comments-by:': 'ref-advanced-search-comments-by'

funMap =
  'type:': 'xxxxRankerize'


