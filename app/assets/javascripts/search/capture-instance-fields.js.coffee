
window.captureInstanceFields = (fields) ->
  console.log("captureInstanceFields")
  _.each(fieldMap,clearField)
  $('a#advanced-search-tab-link-instance').click()
  $('select#instance-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#instance-advanced-search-set-size').val(fields.setSize)
  $('#instance-advanced-search-name').val(fields.term)
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
  console.log("setAssertion. pair.field: #{pair.field}; pair.value: #{pair.value}; key: #{key}")
  canonicalField = canonicalizeField(pair.field)
  console.log("canonicalField: #{canonicalField}")
  assertionField = assertionMap[canonicalField]
  console.log("assertionField: #{assertionField}")
  $("##{assertionField}").prop('checked',true)
  
canonMap =
  'c:': 'citation:'

fieldMap =
  'type:' : 'instance-advanced-search-type' 
  'page:' : 'instance-advanced-search-page' 
  'page-qualifier:' : 'instance-advanced-search-page-qualifier' 
  'adnot:' : 'instance-advanced-search-comments' 
  'adnot-by:' : 'instance-advanced-search-comments-by' 
  'notes:' : 'instance-advanced-search-notes' 
  'note-key:' : 'instance-advanced-search-note-key' 

funMap =
  'xtype:': 'RefTyperize'

assertionMap =
  'cites-an-instance:': 'instance-cites-an-instance'
  'is-cited-by-an-instance:': 'instance-is-cited-by-an-instance'
  'does-not-cite-an-instance:': 'instance-does-not-cite-an-instance'
  'is-not-cited-by-an-instance:': 'instance-is-not-cited-by-an-instance'

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
 

