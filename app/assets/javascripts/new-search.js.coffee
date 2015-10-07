
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
  console.log("parseSearchString for: #{searchString}")
  searchTokens = searchString.split(" ")
  [action,searchTokens] = parseAction(searchTokens)
  [setSize,searchTokens] = parseSetSize(searchTokens)
  [target,searchTokens] = parseSearchTarget(searchTokens)
  [term,searchTokens] = parseDefaultSearchTerm(searchTokens)
  fields = {action: action, setSize: setSize, target: target, conditions: "", format: "", term: term}
  console.log("Action: #{fields.action}")
  console.log("Target: #{fields.target}")
  console.log("SetSize: #{fields.setSize}")
  console.log("term: #{fields.term}")
  fields

parseAction = (tokens) ->
  defaultAction = 'list'
  switch tokens[0]
    when "count" then action = "count";  tokens = _.rest(tokens)
    when "list" then  action = "list";   tokens = _.rest(tokens)
    else              action = defaultAction
  [action, tokens]

parseSetSize = (tokens) ->
  defaultSetSize = '100'
  tokens = [defaultSetSize] unless tokens[0]
  switch 
    when tokens[0].match(/[0-9]+/) then setSize = parseInt(tokens[0]); tokens = _.rest(tokens)
    else                                setSize = parseInt(defaultSetSize)
  [setSize, tokens]

parseSearchTarget = (tokens) ->
  tokens = ['name'] unless tokens[0]
  defaultTarget = 'names'
  switch 
    when tokens[0].match(/^author/i)    then target = "authors";  tokens = _.rest(tokens)
    when tokens[0].match(/^name/i)      then target = "names";  tokens = _.rest(tokens)
    when tokens[0].match(/^reference/i) then target = "references";  tokens = _.rest(tokens)
    when tokens[0].match(/^instance/i)  then target = "instances";  tokens = _.rest(tokens)
    when tokens[0].match(/^tree/i)      then target = "tree";  tokens = _.rest(tokens)
    else                                    target = defaultTarget
  [target, tokens]

isFieldName = (str) ->
  str.match(/:/)

parseDefaultSearchTerm = (tokens) ->
  ndx = _.findIndex(tokens,isFieldName)
  if ndx >= 0
    termTokens = tokens.slice(0,ndx)
    term = termTokens.join(' ')
    tokens = tokens.slice(ndx)
  else # no field
    term = tokens.join(' ')
    tokens = []
  [term,tokens]

  #####

jQuery -> 
  console.log('new search')
  $('body').on('click','#name-advanced-search-capture', (event) ->         captureSearch(event,$(this)))

