
key.filter = (event) ->
  tagName = (event.target or event.srcElement).tagName
  #key.setScope (if /^(INPUT|TEXTAREA|SELECT)$/.test(tagName) then "input" else "other")
  true

key 'ctrl+n, ctrl+shift+n', -> 
  $('#nav').focus()
  debug('nav')
  off

key 'ctrl+s, ctrl+shift+s', -> 
  debug('search')
  $('#query').focus()
  off

# Hitting space key should be like clicking a stylish "checkbox".
key 'space', 'other', (event) -> 
  if $(event.target).hasClass('acts-as-checkbox')
    event.target.click()
  off
 
  
