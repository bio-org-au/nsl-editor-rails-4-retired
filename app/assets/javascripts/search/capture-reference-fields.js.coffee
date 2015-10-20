
window.captureReferenceFields = (fields) ->
  console.log("captureReferenceFields")
  _.each(fieldMap,clearField)
  $('a#advanced-search-tab-link-reference').click()
  $('select#ref-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#ref-advanced-search-set-size').val(fields.setSize)
  $('#ref-advanced-search-citation').val(fields.term)
  _.each(assertionMap,clearAssertion)
  _.each(fields.wherePairs,setFieldValue)
  _.each(fields.wherePairs,setAssertion)
 
clearField = (value,key,list) ->
  $("##{value}").val('')

clearAssertion = (value,key,list) ->
  $("##{value}").prop('checked',false)

setFieldValue = (pair,key,list) ->
  canonicalField = canonicalizeField(pair.field)
  formField = fieldMap[canonicalField]
  canonicalValue = canonicalizeValue(canonicalField,pair.value)
  $("##{formField}").val(canonicalValue)

setAssertion = (pair,key,list) ->
  canonicalField = canonicalizeField(pair.field)
  assertionField = assertionMap[canonicalField]
  $("##{assertionField}").prop('checked',true)
  
canonMap =
  'c:': 'citation:'

fieldMap =
  'citation:' : 'ref-advanced-search-citation' 
  'type:' : 'ref-advanced-search-type' 
  'author:' : 'ref-advanced-search-author' 
  'year:' : 'ref-advanced-search-year' 
  'parent-citation:' : 'ref-advanced-search-parent-citation' 
  'parent-title:' : 'ref-advanced-search-parent-title' 
  'comments:' : 'ref-advanced-search-comments' 
  'comments-by:' : 'ref-advanced-search-comments-by' 

funMap =
  'xtype:': 'RefTyperize'

assertionMap =
  'is-a-duplicate:': 'ref-is-a-duplicate'
  'is-not-a-duplicate:': 'ref-is-not-a-duplicate'
  'is-a-parent:': 'ref-is-a-parent'
  'is-not-a-parent:': 'ref-is-not-a-parent'
  'is-a-child:': 'ref-is-a-child'
  'is-not-a-child:': 'ref-is-not-a-child'

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
 
xcanonicalizeValue = (field,value) ->
  value

window.refTyperize = (value) ->
  console.log("refTyperize for: #{value}")
  "type: #{value.toLowerCase()}"
 

