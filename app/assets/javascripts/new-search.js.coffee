
# Action        Set Size   Target                                    DefaultFieldCriterion  [field:criterion].... 
# [list|count] [set-size] [names|references|authors|instances|tree] [default field string]  [field:criterion].... 
#

window.captureSearch = (event,$capture_button) ->
  console.log('captureSearch')
  str = $('#query-string-field').val();
  console.log(str)
  fields = parseSearchString(str)
  assignFields(fields)

window.parseSearchString = (searchString, verbose = false) ->
  console.log(" ")
  console.log("parseSearchString for: #{searchString}")
  searchTokens = searchString.trim().split(" ")
  [action,searchTokens] = parseAction(searchTokens)
  [setSize,limited, searchTokens] = parseSetSize(searchTokens)
  [target,searchTokens] = parseSearchTarget(searchTokens)
  [term,searchTokens] = parseDefaultSearchTerm(searchTokens)
  [wherePairs,searchTokens] = parseWherePairs(searchTokens)
  fields = {action: action, limited: limited, setSize: setSize, target: target, conditions: "", format: "", term: term, wherePairs: wherePairs}
  console.log("Action: #{fields.action}")
  console.log("Target: #{fields.target}")
  console.log("Limited: #{fields.limited}")
  console.log("SetSize: #{fields.setSize}")
  console.log("term: #{fields.term}")
  console.log("wherePairs: #{fields.wherePairs}")
  fields

parseAction = (tokens) ->
  defaultAction = 'list'
  switch tokens[0]
    when "count" then action = "count";  tokens = _.rest(tokens)
    when "list" then  action = "list";   tokens = _.rest(tokens)
    else              action = defaultAction
  [action, tokens]

parseSetSize = (tokens) ->
  console.log("parseSetSize for tokens: #{tokens.join(',')}")
  defaultSetSize = 100
  tokens = [defaultSetSize.toString()] unless tokens[0]
  switch 
    when tokens[0].match(/[0-9]+/) then limited = true; setSize = parseInt(tokens[0]); tokens = _.rest(tokens)
    when tokens[0].match(/^all$/i) then limited = false; setSize = defaultSetSize; tokens = _.rest(tokens)
    else                                limited = true; setSize = defaultSetSize
  [setSize, limited, tokens]

parseSearchTarget = (tokens) ->
  defaultTarget = 'names'
  tokens = [defaultTarget] unless tokens[0]
  switch 
    when tokens[0].match(/^authors{0,1}$/i)    then target = "authors";  tokens = _.rest(tokens)
    when tokens[0].match(/^names{0,1}$/i)      then target = "names";  tokens = _.rest(tokens)
    when tokens[0].match(/^references$/i)      then target = "references";  tokens = _.rest(tokens)
    when tokens[0].match(/^refs{0,1}$/i)       then target = "references";  tokens = _.rest(tokens)
    when tokens[0].match(/^instances{0,1}$/i)  then target = "instances";  tokens = _.rest(tokens)
    when tokens[0].match(/^tree$/i)            then target = "tree";  tokens = _.rest(tokens)
    else                                            target = defaultTarget
  [target, tokens]

isFieldName = (str) ->
  str.match(/:/)

parseDefaultSearchTerm = (tokens) ->
  console.log("parseDefaultSearchTerm for tokens: #{tokens}")
  ndx = _.findIndex(tokens,isFieldName)
  if ndx >= 0
    termTokens = tokens.slice(0,ndx)
    term = termTokens.join(' ')
    tokens = tokens.slice(ndx)
  else # no field
    term = tokens.join(' ')
    tokens = []
  [term,tokens]

parseWherePairs = (tokens) ->
  console.log("parseWherePairs for: #{tokens.join(' ')}")
  wherePairs = []
  while tokens.length > 0
    [pair, tokens] = parseOnePair(tokens)
    wherePairs.push(pair) if pair
  [wherePairs, tokens]

parseOnePair = (tokens) ->
  console.log("parseOneWherePair for: #{tokens.join(' ')}")
  switch 
    when tokens.length == 0
      pair = null 
      tokens = []
    when isFieldName(tokens[0])
      field = tokens[0]
      [value,tokens] = parseOneValue(tokens.slice(1))
      console.log("Got back value: #{value}")
      pair = {field: field, value: value}
    else
      throw "Exception!!! Expected '#{tokens[0]}' to be a field name"
  [pair, tokens]

parseOneValue = (tokens) ->
  console.log("parseOneValue for: #{tokens.join(' ')}")
  value = ""
  until tokens.length == 0 || isFieldName(tokens[0])
    console.log("token zero: #{tokens[0]}")
    value += " #{tokens[0]}"
    tokens = tokens.slice(1)
  console.log("Returning: value: #{value}")
  [value.trim(), tokens]

assignFields = (fields) ->
  switch 
    when fields.target.match(/^authors$/i)    then window.assignAuthorFields(fields)
    when fields.target.match(/^names$/i)      then window.assignNameFields(fields)
    when fields.target.match(/^references$/i) then window.assignReferenceFields(fields)
    when fields.target.match(/^instances$/i)  then window.assignInstanceFields(fields)
    when fields.target.match(/^tree$/i)      then window.assignTreeFields(fields)
    else                                     window.assignNameFields(fields)



  ####

jQuery -> 
  console.log('new search')
  $('body').on('click','#name-advanced-search-capture', (event) ->         captureSearch(event,$(this)))

