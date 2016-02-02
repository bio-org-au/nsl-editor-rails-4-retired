
window.captureAuthorFields = (fields) ->
  console.log("captureAuthorFields")
  _.each(fieldMap,clearField)
  $('a#advanced-search-tab-link-author').click()
  $('select#author-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#author-advanced-search-set-size').val(fields.setSize)
  $('#author-advanced-search-name').val(fields.term)
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
  'n:': 'name:'
  'a:': 'abbrev:'

fieldMap =
  'name:' : 'author-advanced-search-name'
  'abbrev:' : 'author-advanced-search-abbrev'
  'extra-name-text:' : 'author-advanced-search-full-name'
  'ipni-id:' : 'author-advanced-search-ipni-id'
  'comments:' : 'author-advanced-search-comments'
  'comments-by:' : 'author-advanced-search-comments-by'

funMap =
  'x:': ''

assertionMap =
  'is-a-duplicate:': 'author-is-a-duplicate'
  'is-not-a-duplicate:': 'author-is-not-a-duplicate'

canonicalizeField = (field) ->
  if canonMap.hasOwnProperty(field)
    canonMap[field]
  else
    field

canonicalizeValue = (field,value) ->
  if funMap.hasOwnProperty(field)
    functionName = funMap[field]
    fun = window[functionName]
    if typeof(fun) == "function"
      canonicalValue = fun(value)
    else
      throw new Error("No such function: #{functionName}")
  else
    canonicalValue = value
  canonicalValue

xcanonicalizeValue = (field,value) ->
  value

window.refTyperize = (value) ->
  console.log("refTyperize for: #{value}")
  "type: #{value.toLowerCase()}"
