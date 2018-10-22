window.debug = (s) ->
  try
    console.log('debug: ' + s) if debugSwitch == true
  catch error

window.notice = (s) ->
  try
    console.log('notice: ' + s)
  catch error

window.debugObject = (obj) ->
  debug('show object')
  $.each obj, (key, element) ->
    debug("key: " + key + "\n" + "value: " + element) if element
  return
 

jQuery -> 
  debug('Start of fresh.js document ready')
  debug('jQuery version: ' + $().jquery)
  $('body').on('click','.edit-details-tab', (event) ->                 loadDetails(event,$(this),true))
  $('body').on('click','.change-name-category-on-edit-tab', (event) -> changeNameCategoryOnEditTab(event,$(this),true))
  $('body').on('click','#master-checkbox.stylish-checkbox', (event) -> masterCheckboxClicked(event,$(this)))

  $('tr.search-result').keydown (event) ->                             searchResultKeyNavigation(event,$(this))
  $('body').on('focus','tr.search-result td.takes-focus', (event) ->   searchResultFocus(event,$(this).parent('tr')))
  $('body').on('click','tr.search-result td.takes-focus', (event) ->   searchResultFocus(event,$(this).parent('tr')))

  $('tr.search-result td.takes-focus').focus (event) ->                searchResultFocus(event,$(this).parent('tr'))
  # iPad
  $('tr.search-result td.takes-focus').click (event) ->                searchResultFocus(event,$(this).parent('tr'))
  # iPad
  $('body').on('click','div#search-results tr.search-result .stylish-checkbox', (event) -> clickSearchResultCB(event,$(this)))
  # 
  $('a#'+window.location.hash).click() if window.location.hash
  $('body').on('click','a.append-to-query-field', (event) ->               appendToQueryField(event,$(this)))
  $('body').on('click','a.clear-query-field', (event) ->                   clearQueryField(event,$(this)))
  $('body').on('click','a.instance-note-delete-link', (event) ->           deleteInstanceNote(event,$(this)))
  $('body').on('click','a.instance-note-cancel-delete-link', (event) ->    cancelDeleteInstanceNote(event,$(this)))
  $('body').on('click','a.instance-note-cancel-edit-link', (event) ->      cancelInstanceNoteEdit(event,$(this)))
  $('body').on('change','.instance-note-key-id-select', (event) ->         instanceNoteKeyIdSelectChanged(event,$(this)))
  $('body').on('click','.build-query-button', (event) ->                   buildQueryString(event,$(this)))
  $('#search-field').change (event) ->                                     searchFieldChanged(event,$(this))
  $('body').on('change','select#query-on', (event) ->                      queryonSelectChanged(event,$(this)))
  # $('body').on('click','li.dropdown-submenu a', (event) ->                 dropdownSubmenuClick(event,$(this)))
  $('body').on('click','a.unconfirmed-delete-link', (event) ->             unconfirmedActionLinkClick(event,$(this)))
  $('body').on('click','a.unconfirmed-action-link', (event) ->             unconfirmedActionLinkClick(event,$(this)))
  $('body').on('click','a.cancel-link', (event) ->                         cancelLinkClick(event,$(this)))
  $('body').on('click','a.cancel-action-link', (event) ->                  cancelLinkClick(event,$(this)))
  $('body').on('click','#refresh-page-from-details-link', (event) ->       refreshPageLinkClick(event,$(this)))
  $('body').on('click','.refresh-page-link', (event) ->                    refreshPageLinkClick(event,$(this)))
  $('body').on('change','#name_name_rank_id', (event) ->                   nameRankIdChanged(event,$(this)))
  $('body').on('click','.cancel-new-record-link', (event) ->               cancelNewRecord(event,$(this)))
  $('body').on('click','#instance-reference-typeahead', (event) ->         $(this).select())
  $('body').on('click','.tree-row div.head', (event) ->                    treeRowClicked(event,$(this)))
  $('body').on('submit','#name-delete-form', (event) ->                    nameDeleteFormSubmit(event,$(this)))
  $('body').on('click','#confirm-name-refresh-children-button', (event) -> confirmNameRefreshChildrenButtonClick(event,$(this)))
  $('body').on('keydown','#copy-name-form', (event) ->                     copyNameFormEnter(event,$(this)))
  $('body').on('click','#create-copy-of-name', (event) ->                  createCopyOfNameClick(event,$(this)))
  debug("on load - search-target-button-text: " + $('#search-target-button-text').text().trim())

  # When tabbing to search-result record, need to click to trigger retrieval of details.
  $('a.show-details-link[tabindex]').focus (event) ->                      clickOnFocus(event,$(this))
  optionalFocusOnPageLoad()
  $('.firefox-notice').removeClass('hidden') if window.navigator.userAgent.indexOf("Firefox") < 0
  debug('End of fresh.js document ready.')

optionalFocusOnPageLoad = ->
  focusId = $('#focus-id').val()
  focusSelector = "#search-result-#{focusId} td a.show-details-link"
  if $(focusSelector).length == 1
    $(focusSelector).focus()
  else
    $('table.search-results tr td.takes-focus a.show-details-link[tabindex]').first().focus() 


window.showInstanceWasCreated = (recordId,fromRecordType,fromRecordId) ->
  debug("showInstanceWasCreated: recordId: #{recordId}; fromRecordType: #{fromRecordType}; fromRecordId: #{fromRecordId}")

window.showRecordWasDeleted = (recordId,recordType) ->
  $("#search-result-details").addClass('hidden')
  $('#search-result-details').html('');
  $("#search-result-#{recordId}").addClass('hidden')

window.cancelNewRecord = (event,$element) ->
  $("#search-result-details").addClass('hidden')
  $("##{$element.attr('data-element-id')}").addClass('hidden')
  return false

confirmNameRefreshChildrenButtonClick = (event,$the_button) ->
  debug('confirmNameRefreshChildrenButtonClick')
  $the_button.attr('disabled','true')
  $('#cancel-refresh-children-link').attr('disabled','true')
  $('#name-refresh-tab').attr('disabled','true')
  $('#search-result-details-error-message-container').html('')
  $('#refresh-children-spinner').removeClass('hidden')

copyNameFormEnter = (event,$the_button) ->
  key = event.which
  enter_key_code = 13
  if (key == enter_key_code)
    if ($('#confirm-or-cancel-copy-name-link-container').hasClass('hidden'))
      # Show the confirm/cancel buttons
      $('#confirm-or-cancel-copy-name-link-container').removeClass('hidden')
      return false
    else
      $('#create-copy-of-name').click()
      return false
  else
    return true

createCopyOfNameClick = (event,$the_element) ->
  debug('createCopyOfNameClick')
  $('#copy-name-error-message-container').html('')
  $('#copy-name-error-message-container').addClass('hidden');
  $('#copy-name-info-message-container').html('')
  $('#copy-name-info-message-container').addClass('hidden');
  return true

nameDeleteFormSubmit = (event,$element) ->
  $('#confirm-delete-name-button').attr('disabled','true')
  $('#cancel-delete-link').attr('disabled','true')
  $('#name-delete-tab').attr('disabled','true').addClass('disabled')
  $('#search-result-details-error-message-container').html('')
  $('#name-delete-spinner').removeClass('hidden')
  return true

refreshPageLinkClick = (event,$element) ->
  location.reload()

window.setDependents = (fieldId) ->
  fieldSelector = "##{fieldId}"
  fieldValue = $(fieldSelector).val()
  fieldValue = fieldValue.replace(/\s/g,'')
  if fieldValue == ''
    $(".requires-#{fieldId}[value=='']").attr('disabled','true')
    $("input.requires-#{fieldId}").removeClass('enabled').addClass('disabled')
    $(".hide-if-#{fieldId}").removeClass('hidden')
  else
    $(".requires-#{fieldId}").removeAttr('disabled')
    $("input.requires-#{fieldId}").removeClass('disabled').addClass('enabled')
    $(".hide-if-#{fieldId}").addClass('hidden')

nameRankIdChanged = (event,$element) ->
  if $element.val() == ""
    $('.requires-rank').attr('disabled','true')
    $('input.requires-rank').removeClass('enabled').addClass('disabled')
    $('.hide-if-rank').removeClass('hidden')
  else
    $('.requires-rank').removeAttr('disabled')
    $('input.requires-rank').removeClass('disabled').addClass('enabled')
    $('.hide-if-rank').addClass('hidden')

# Do NOT close the menu when submenu is clicked.
dropdownSubmenuClick = (event,$element) ->
  event.preventDefault()
  event.stopPropagation()

showSearchResultDetailsIfMenusClosed = ->
  debug('showSearchResultDetailsIfMenusClosed')
  if $('li.dropdown.open').length == 0
    $('#search-result-details').show()

hideSearchResultDetailsIfMenusOpen = ->
  debug('hideSearchResultDetailsIfMenusOpen')
  if $('li.dropdown.open').length > 0
    $('#search-result-details').hide()

queryonSelectChanged = (event,$element) ->
  debug("queryonSelectChanged to: #{$element.val()} ")
  switch $element.val()
    when 'author' then setAuthorQueryOptions()
    when 'instance' then setInstanceQueryOptions()
    when 'name' then setNameQueryOptions()
    when 'reference' then setReferenceQueryOptions()
    when 'tree' then setTreeQueryOptions()
  $('#query-field').focus()

window.setAuthorQueryOptions = ->
  debug('setAuthorQueryOptions')
  populateSelect($('select#query-field'),authorQueryOptions)
  populateList($('ul#query-list'),$('#author-query-options-storage').html())
  $('#query_common_and_cultivar').attr('disabled',true)
  $('#query_common_and_cultivar_label').addClass('disabled')

window.setInstanceQueryOptions = ->
  debug('setInstanceQueryOptions')
  populateSelect($('select#query-field'),instanceQueryOptions)
  populateList($('ul#query-list'),$('#instance-query-options-storage').html())
  $('#query_common_and_cultivar').attr('disabled',true)
  $('#query_common_and_cultivar_label').addClass('disabled')

window.setNameQueryOptions = ->
  debug('setNameQueryOptions')
  populateSelect($('select#query-field'),nameQueryOptions)
  populateList($('ul#query-list'),$('#name-query-options-storage').html())
  $('#query_common_and_cultivar').removeAttr('disabled')
  $('#query_common_and_cultivar_label').removeClass('disabled')

window.setReferenceQueryOptions = ->
  debug('setReferenceQueryOptions')
  populateSelect($('select#query-field'),referenceQueryOptions)
  populateList($('ul#query-list'),$('#reference-query-options-storage').html())
  $('#query_common_and_cultivar').attr('disabled',true)
  $('#query_common_and_cultivar_label').addClass('disabled')

window.setTreeQueryOptions = ->
  debug('setTreeQueryOptions')
  allowBlank = false
  populateSelect($('select#query-field'),treeQueryOptions, allowBlank)
  # no tree query options here
  $('#query_common_and_cultivar').attr('disabled',true)
  $('#query_common_and_cultivar_label').addClass('disabled')

window.populateSelect = (select,options, allowBlank = true) ->
  select.empty()
  select.append("<option value=''></option>") if allowBlank
  for value, display of options
    select.append("<option value='#{value}'>#{display}</option>")

populateList = (unorderedList,newContent) ->
  debug('populateList')
  unorderedList.html('')
  unorderedList.html(newContent)

searchFieldChanged = (event,$element) ->
  debug('searchFieldChanged')
  $('select#query-on').val('author') if $('#search-field').val().match(/authors*:/)
  $('select#query-on').val('instance') if $('#search-field').val().match(/instances*:/)
  $('select#query-on').val('instance') if $('#search-field').val().match(/name.usages*:/)
  $('select#query-on').val('name') if $('#search-field').val().match(/names*:/)
  $('select#query-on').val('reference') if $('#search-field').val().match(/refs*:/)

buildQueryString = (event,$element) ->
  debug('BuildQueryString')
  search_string = ''
  search_string += 'name: ' if ($('#name-full-name').val() || 
                                $('#name-simple-name').val() ||
                                $('#name-name-element').val() ||
                                $('#name-name-type').val() ||
                                $('#name-name-author').val() )
  search_string += " fn: #{$('#name-full-name').val()} " if $('#name-full-name').val()
  search_string += " sn: #{$('#name-simple-name').val()} " if $('#name-simple-name').val()
  search_string += " na: #{$('#name-name-author').val()} " if $('#name-name-author').val()
  search_string += " nt: #{$('#name-name-type').val()} " if $('#name-name-type').val()
  search_string += " ne: #{$('#name-name-element').val()} " if $('#name-name-element').val()
  search_string += ";" if search_string.length > 0

  search_string += " ci: #{$('#reference-citation').val()} " if $('#reference-citation').val()
  search_string += " y: #{$('#reference-year').val()} " if $('#reference-year').val()
  search_string += " pt: #{$('#reference-parent-title').val()} " if $('#reference-parent-title').val()
  search_string += " an: #{$('#author-name').val()} " if $('#author-name').val()
  $('#search-field').val(search_string)
  event.preventDefault()
 
instanceNoteKeyIdSelectChanged = (event,$element) ->
  debug('instanceNoteKeyIdSelectChanged')
  instanceNoteId = $element.attr('data-instance-note-id')
  instanceNoteEnableOrDisableSaveButton(event,$element,instanceNoteId)
  event.preventDefault()

# Disable save button if either mandatory field is empty.
instanceNoteEnableOrDisableSaveButton = (event,$element,instanceNoteId) ->
  debug('instanceNoteEnableOrDisableSaveButton')
  if ($("#instance-note-key-id-select-#{instanceNoteId}").val().length == 0 ||
     $("#instance-note-value-text-area-#{instanceNoteId}").val().length == 0)
    $("#instance-note-save-btn-#{instanceNoteId}").addClass('disabled')
  else
    $("#instance-note-save-btn-#{instanceNoteId}").removeClass('disabled')
  event.preventDefault()
  
  
# Cancel editing for a specific instance note.
cancelInstanceNoteEdit = (event,$element) ->
  debug('cancelInstanceNoteEdit')
  instanceNoteId = $element.attr('data-instance-note-id')
  # Cancel the delete confirmation dialog if in progress.
  $("a#instance-note-cancel-delete-link-#{instanceNoteId}").not('.hidden').click()
  # Throw the form away.
  $("div#instance-note-edit-form-container-#{$element.attr('data-instance-note-id')}").text('')
  # Show the edit link.
  $("#instance-note-edit-link-#{instanceNoteId}").removeClass('hidden')
  # Hide the cancel edit link.
  $("#instance-note-cancel-edit-link-#{instanceNoteId}").addClass('hidden')
  # Hide the delete link.
  $("#instance-note-delete-link-#{instanceNoteId}").addClass('hidden')
  # Enable the (hidden) delete link.
  $("#instance-note-delete-link-#{instanceNoteId}").removeClass('disabled')
  # This doesn't this work: a delay occurs as a request is made to the server!
  #event.preventDefault()
  return(false)
 
cancelDeleteInstanceNote = (event,$element) ->
  debug('cancelDeleteInstanceNote')
  instanceNoteId = $element.attr('data-instance-note-id')
  debug(instanceNoteId)
  $("#instance-note-delete-link-#{instanceNoteId}").removeClass('disabled')
  $element.parent().addClass('hidden')
  debug($element.parent().parent().children('span.delete').children('a.disabled').length)
  $element.parent().parent().children('span.delete').children('a.disabled').removeClass('disabled')
  $("##{$element.attr('data-confirm-btn-id')}").addClass('hidden')
  event.preventDefault()

unconfirmedActionLinkClick = (event,$element) ->
  debug('unconfirmedActionLinkClick')
  $("##{$element.attr('data-show-this-id')}").removeClass('hidden')
  $element.addClass('disabled')
  $('.message-container').html('')
  event.preventDefault()

cancelLinkClick = (event,$element) ->
  debug('cancelLinkClick')
  debug("data-hide-this-id: #{$element.attr('data-hide-this-id')}")
  debug("data-enable-this-id: #{$element.attr('data-enable-this-id')}")
  $("##{$element.attr('data-hide-this-id')}").addClass('hidden')
  $("##{$element.attr('data-enable-this-id')}").removeClass('disabled')
  $(".#{$element.attr('data-empty-this-class')}").html('')
  $('.message-container').html('')
  $('.error-container').html('')
  event.preventDefault()

deleteInstanceNote = (event,$element) ->
  debug('deleteInstanceNote')
  instanceNoteId = $element.attr('data-instance-note-id')
  $("#instance-note-delete-link-#{instanceNoteId}").addClass('disabled')
  $("#confirm-or-cancel-delete-instance-note-#{instanceNoteId}").removeClass('hidden')
  event.preventDefault()

clearQueryField = (event,$element) ->
  $('#search-field').val('')
  event.preventDefault()

appendToQueryField = (event,$element) ->
  $('#search-field').val($('#search-field').val() + ' ' + $element.attr('data-value'))
  event.preventDefault()

clickOnFocus = (event,$element) ->
  debug("clickOnFocus: id: #{$element.attr('id')}; event target: #{event.target}")
  $element.click()

showFieldIsNotYetSaved = ($element) ->
  $element.addClass('changed').addClass('not-saved')
  return

selectedRecords = -> 
  return $('div#search-results tr td.checkbox-container .stylish-checkbox-checked')

serializeSelectedRecords = () ->
  result = ''
  selectedRecords().each (index) -> 
    debug($(this).closest('tr.search-result').attr('data-record-id'))
    debug($(this).closest('tr.search-result').attr('data-record-type'))
    result += "#{$(this).closest('tr.search-result').attr('data-record-type')}:#{$(this).closest('tr.search-result').attr('data-record-id')},"
  return result

serializeSelectedIds = () ->
  queryIds = ''
  selectedRecords().each (index) -> queryIds += $(this).closest('tr.search-result').attr('data-record-id')+','
  return queryIds.replace(/,$/,'')

window.loadTreeDetails = (event,inFocus,tabWasClicked = false) ->
  debug('window.loadTreeDetails')
  $('#search-result-details').show()
  $('#search-result-details').removeClass('hidden')
  record_type = 'instance' #$('tr.showing-details').attr('data-record-type')
  instance_id = $('.showing-details').attr('data-instance-id')
  tabIndex = 1 #$('.search-result.showing-details a[tabindex]').attr('tabindex')
  debug("tabIndex: #{tabIndex}")
  url = "#{inFocus.attr('data-edit-url').replace(/0/,'')}#{inFocus.attr('data-instance-id')}?tab=#{currentActiveTab(record_type)}&tabIndex=#{tabIndex}&rowType=#{inFocus.attr('data-row-type')}"
  debug("url: #{url}")
  $('#search-result-details').load  url, -> 
    debug("after get")
    recordCurrentActiveTab(record_type)
    if tabWasClicked
      debug('tab clicked')
      if $('.give-me-focus') 
        debug('give-me-focus ing')
        $('.give-me-focus').focus()
      else
        debug('just focus the tab')
        $('li.active a.tab').focus()
  event.preventDefault()

changeNameCategoryOnEditTab = (event,$this,tabWasClicked) ->
  debug('changeNameCategoryOnEditTab')
  $('#search-result-details').load($this.attr('data-edit-url'))

window.loadDetails = (event,inFocus,tabWasClicked = false) ->
  debug('window.loadDetails')
  $('#search-result-details').show()
  $('#search-result-details').removeClass('hidden')
  record_type = $('tr.showing-details').attr('data-record-type')
  instance_type = $('tr.showing-details').attr('data-instance-type')
  row_type = $('tr.showing-details').attr('data-row-type')
  tabIndex = $('.search-result.showing-details a[tabindex]').attr('tabindex')
  url = inFocus.attr('data-tab-url').replace(/active_tab_goes_here/,currentActiveTab(record_type))
  url = url+'?tabIndex='+tabIndex+'&row-type='+row_type+'&instance-type='+instance_type+'&rowType='+inFocus.attr('data-row-type')
  $('#search-result-details').load  url, -> 
    recordCurrentActiveTab(record_type)
    if tabWasClicked
      debug('tab clicked')
      if $('.give-me-focus') 
        debug('give-me-focus ing')
        $('.give-me-focus').focus()
      else
        debug('just focus the tab')
        $('li.active a.tab').focus()
  event.preventDefault()
 
currentActiveTab = (record_type) ->
  debug "  state of " + record_type + " tab: #{$('body').attr('data-active-'+record_type+'-tab')}"
  return $('body').attr('data-active-'+record_type+'-tab')

recordCurrentActiveTab = (record_type) -> 
  $('body').attr('data-active-'+record_type+'-tab',$('div#search-result-details ul.nav-tabs li.active a').attr('data-tab-name'))  
  
treeRowClicked2 = (event,$this,data) ->
  debug('treeRowClicked2')

treeRowClicked = (event,$this) ->
  debug('treeRowClicked')
  unless $this.hasClass('showing-details')
    changeTreeFocus(event,$this)
    $('#search-results.nothing-selected').removeClass('nothing-selected').addClass('something-selected')
  event.preventDefault()

searchResultFocus = (event,$this) ->
  debug('searchResultFocus')
  unless $this.hasClass('showing-details')
    changeFocus(event,$this)
    $('#search-results.nothing-selected').removeClass('nothing-selected').addClass('something-selected')
  event.preventDefault()

changeTreeFocus = (event,inFocus) ->
  debug("changeTreeFocus: id: #{inFocus.attr('id')}; event target: #{event.target}")
  $('.showing-details').removeClass('showing-details')
  inFocus.addClass('showing-details')
  loadTreeDetails(event,inFocus)
  event.preventDefault()

changeFocus = (event,inFocus) ->
  debug("changeFocus: id: #{inFocus.attr('id')}; event target: #{event.target}")
  $('.showing-details').removeClass('showing-details')
  inFocus.addClass('showing-details')
  loadDetails(event,inFocus)
  #inFocus.focus()
  event.preventDefault()

searchResultKeyNavigation = (event,$this) ->
  debug('searchResultKeyNavigation ')
  arrowLeft = 37
  arrowRight = 39
  arrowUp = 38
  arrowDown = 40
  keep_going = false
  switch event.keyCode
    when arrowLeft
      moveToSearchResultDetails($this,'last')
    when arrowRight
      moveToSearchResultDetails($this,'first')
    when arrowUp
      moveUpOneSearchResult($this)
    when arrowDown
      moveDownOneSearchResult($this)
    else
      keep_going = true
  event.preventDefault() unless keep_going

clickSearchResultCB = (event,$this) ->
  debug('clickSearchResultCB')
  if $this.hasClass('stylish-checkbox-checked')
    unCheckSearchResultCB(event,$this)
  else
    checkSearchResultCB(event,$this)
  event.preventDefault() 

unCheckSearchResultCB = (event,$this) ->
  debug('unCheckSearchResultCB')
  $this.removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked')

checkSearchResultCB = (event,$this) ->
  debug('checkSearchResultCB')
  $this.removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked')

searchResultRecordType = ->
  debug(searchResultsCheckedCount())
  debug $('#search-results tr.search-result .stylish-checkbox-checked').length
  $('#search-results tr.search-result .stylish-checkbox-checked').closest('tr').attr('data-record-type')

searchResultsCheckedCount = ->
  $('#search-results tr.search-result .stylish-checkbox-checked').length

window.hideTools = ->
  $('#toolbar a').addClass('hidden')

window.showToolsForNothingSelected = ->
  $('#toolbar a.show-when-nothing-selected').removeClass('hidden')

showToolsForSomethingSelected = ->
  $('#toolbar a.show-when-something-selected').removeClass('hidden')

window.showToolsForOneThingSelected = ->
  debug('showToolsForOneThingSelected')
  showToolsForSomethingSelected()
  $('#toolbar a.show-when-one-thing-selected').removeClass('hidden')
  selector = '#toolbar a.show-when-one-' + searchResultRecordType()
  selector += '-selected'  # Put here to avoid confusing compiler.
  $(selector).removeClass('hidden')
  assignSingleSelectedIdToLinks()

showToolsForTwoOrMoreThingsSelected = ->
  showToolsForSomethingSelected()
  $('#toolbar a.show-when-two-or-more-things-selected').removeClass('hidden')

# Set up the link in the button(s) to reference the id of the selected item.
# Not my first choice, but works so far.  Update: turns out to have worked very robustly - no recorded problems.
# Specific to references at the moment ()
assignSingleSelectedIdToLinks = ->
  debug('assignSingleSelectedIdToLinks')
  selectedId = firstSelectedItem().attr('data-record-id')
  debug('selectedId: ' + selectedId)
  $('a.needs-id-of-selected-record').each -> 
    $(this).attr('href',$(this).attr('data-url') + '?' + $(this).attr('data-role-of-selected') + '=' + selectedId + '&record-type='+firstSelectedItem().attr('data-record-type'))

firstSelectedItem = ->
  $('tr.search-result td.checkbox-container .stylish-checkbox-checked').first().closest('tr')

window.showMessage = (message) ->
  debug('showMessage')
  $('#message-container').removeClass('hidden').addClass('visible').html(message)
  setOneClickHider $('#message-container')

window.setOneClickHider = ($target) -> $(document).one "click",  (event) -> hidePopupOrAddHider(event,$target)

# For the "click anywhere outside popup to hide popup" feature.
# This function gets called in the document click anywhere event.
# The aim of that event is to hide the current popup.
# There is a side-effect because that event fires even if the click is in the popup itself,
# which we don't want to hide.
# This fn defuses that case:  if click is in popup, do not hide popup.
# There is a further complication because the hider is bound via "one", 
# so when this function is called you will have consumed that "one" event, so 
# you have to reset the one-off event.
# 
# Now, also restore title from data-title attribute.
hidePopupOrAddHider = (event,$target) ->
  if $(event.target).closest('.popup').length == 0
    closeOpenPopups()
  else
    setOneClickHider($target)
   
closeOpenPopups = ->  $('.popup').removeClass('visible').addClass('hidden')

positionOnTheRight = (clickPosition,$target,offset) ->
  $target.css('left',clickPosition.left+offset)
  $target.css('top',clickPosition.top)

makeTargetVisible = ($target) -> 
  debug("makeTargetVisible: #{$target.attr('id')}")
  $target.removeClass('hidden').addClass('visible')

makeTargetInvisible = ($target) -> 
  $target.removeClass('visible').addClass('hidden')

toggleVisibleHidden = ($target) ->
  if $target.hasClass('hidden')
    makeTargetVisible($target)
  else
    makeTargetInvisible($target)

window.moveUpOneSearchResult = (startRow) -> 
  if startRow.prev()
    startRow.prev().find('a.show-details-link').focus()

window.moveDownOneSearchResult = (startRow) -> 
  startRow.next().find('a.show-details-link').focus()

window.moveToSearchResultDetails = (searchResultDetail,liElementHasClass) -> 
  $('#search-result-details ul li.'+liElementHasClass + ' a').focus()

