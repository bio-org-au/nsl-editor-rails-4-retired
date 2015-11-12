
window.captureNameFields = (fields) ->
  console.log("captureNameFields")
  _.each(fieldMap,clearField)
  $('a#advanced-search-tab-link-name').click()
  $('select#name-advanced-search-list-or-count').val(fields.action.toLowerCase())
  $('#name-advanced-search-set-size').val(fields.setSize)
  $('#name-advanced-search-name').val(fields.term)
  _.each(assertionMap,clearAssertion)
  _.each(fields.wherePairs,setFieldValue)
  _.each(fields.wherePairs,setAssertion)
  setTypeOptions()
 
clearField = (value,key,list) ->
  $("##{value}").val('')
 
clearAssertion = (value,key,list) ->
  $("##{value}").prop('checked',false)

setFieldValue = (pair,key,list) ->
  console.log("setFieldValue: pair.field: #{pair.field}, pair.value: #{pair.value},  key: #{key}")
  canonicalField = canonicalizeField(pair.field)
  formField = fieldMap[canonicalField]
  canonicalValue = canonicalizeValue(canonicalField,pair.value)
  console.log("canonicalValue: #{canonicalValue}")
  $("##{formField}").val(canonicalValue)

setAssertion = (pair,key,list) ->
  canonicalField = canonicalizeField(pair.field)
  assertionField = assertionMap[canonicalField]
  $("##{assertionField}").prop('checked',true)
  
setTypeOptions = ->
 $("select#name-advanced-search-name-type-options option").prop("selected", false)
 listVal = $("#name-advanced-search-name-type-list").val()
 vals = listVal.split(',')
 _.each(vals,selectTypeOption)

selectTypeOption = (val,two,three) ->
  $("select#name-advanced-search-name-type-options option[value='#{val.trim()}']").prop("selected", true)

canonicalizeField = (field) ->
  if canonMap.hasOwnProperty(field)
    canonMap[field]
  else
    field

canonicalizeValue = (field,value) ->
  if assertionMap.hasOwnProperty(field)
    canonicalValue = field
  else 
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
 
window.rankerize = (value) ->
  "rank: #{value.toLowerCase().trim()}"
 
window.belowRankerize = (value) ->
  "below-rank: #{value.toLowerCase().trim()}"
 
window.aboveRankerize = (value) ->
  "above-rank: #{value.toLowerCase().trim()}"
 
window.staterize = (value) ->
  "status: #{value.toLowerCase().trim()}"
 
canonMap =
  'nr:': 'rank:'
  'nt:': 'rank:'

fieldMap =
  'name:': ''
  'rank:': 'name_search_name_rank_id'
  'below-rank:': 'name_search_name_ranked_below'
  'above-rank:': 'name_search_name_ranked_above'
  'type:': 'name-advanced-search-name-type-list'
  'status:': 'name_search_name_status_id'
  'author:': 'name-advanced-search-author-abbrev'
  'ex-author:': 'name-advanced-search-ex-author-abbrev'
  'base-author:': 'name-advanced-search-base-author-abbrev'
  'ex-base-author:': 'name-advanced-search-ex-base-author-abbrev'
  'sanctioning-author:': 'name-advanced-search-sanctioning-author-abbrev'
  'comments:': 'name-advanced-search-comments'
  'comments-by:': 'name-advanced-search-comments-by'

funMap =
  'rank:': 'rankerize'
  'status:': 'staterize'
  'below-rank:': 'belowRankerize'
  'above-rank:': 'aboveRankerize'

assertionMap =
  'is-a-duplicate:': 'name-is-a-duplicate'
  'is-not-a-duplicate:': 'name-is-not-a-duplicate'
  'is-a-parent:': 'name-is-a-parent'
  'is-not-a-parent:': 'name-is-not-a-parent'
  'is-a-child:': 'name-is-a-child'
  'is-not-a-child:': 'name-is-not-a-child'
  'is-a-second-parent:': 'name-is-a-second-parent'
  'is-not-a-second-parent:': 'name-is-not-a-second-parent'
  'has-a-second-parent:': 'name-has-a-second-parent'
  'has-no-second-parent:': 'name-has-no-second-parent'




