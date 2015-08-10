window.debug = (s) ->
  try
    console.log('debug: ' + s)
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
  notice('Start of fresh.js document ready')
  notice('jQuery version: ' + $().jquery)
  $('body').on('click','.for-help-popup', (event) ->                   togglePopUpHelp(event,$(this)))
  $('body').on('click','div#toolbar a.query-set', (event) ->           querySet())
  $('body').on('click','.edit-details-tab', (event) ->                 loadDetails(event,$(this),true))
  $('body').on('click','.change-name-category-on-edit-tab', (event) -> changeNameCategoryOnEditTab(event,$(this),true))
  $('body').on('click','#master-checkbox.stylish-checkbox', (event) -> masterCheckboxClicked(event,$(this)))
  $('body').on('dblclick','input', (event) ->                          selectInputContents(event,$(this)))
  $('body').on('dblclick','textarea', (event) ->                       selectInputContents(event,$(this)))

  $('tr.search-result').keydown (event) ->                             searchResultKeyNavigation(event,$(this))
  $('body').on('focus','tr.search-result td.takes-focus', (event) ->   searchResultFocus(event,$(this).parent('tr')))
  # New records, when saved, gain attributes via Ajax:
  $('body').on('click','tr.search-result td.takes-focus', (event) ->   searchResultFocus(event,$(this).parent('tr')))

  $('tr.search-result td.takes-focus').focus (event) ->                searchResultFocus(event,$(this).parent('tr'))
  # iPad
  $('tr.search-result td.takes-focus').click (event) ->                searchResultFocus(event,$(this).parent('tr'))
  # iPad
  $('body').on('click','div#toolbar a.identify-duplicates', (event) -> identifyDuplicates(event,$(this)))
  $('body').on('click','div#search-results tr.search-result .stylish-checkbox', (event) -> clickSearchResultCB(event,$(this)))
  # 
  $('body').on('click','#query-ref-instances', (event) ->              queryRefInstances(event,$(this)))
  $('body').on('click','#query-ref-names', (event) ->                  queryRefNames(event,$(this)))
  $('body').on('click','#query-name-usages', (event) ->                queryNameUsages(event,$(this)))
  $('body').on('click','#query-name-synonymy', (event) ->              queryNameSynonymy(event,$(this)))
  $('body').on('click','#query-similar-authors-for-author', (event) -> querySimilarAuthorsForAuthor(event,$(this)))
  $('body').on('click','#query-instance-context', (event) ->           queryInstanceContext(event,$(this)))
  $('body').on('click','#create-instance-with-name-and-reference-btn', (event) -> createInstanceWithNameAndReference(event,$(this)))
  $('body').on('click','#attach-name-to-author-btn', (event) ->            attachNameToAuthor(event,$(this)))
  $('body').on('click','#toggle-details-btn', (event) ->                   toggleDetails(event,$(this)))
  $('body').on('change','.save-on-blur', (event) ->                        editFormFieldHasChanged(event,$(this)))
  $('body').on('ajax:error','form.edit-form', (event,xhr,status) ->        editFormAjaxError(event,xhr,status,$(this)))
  #$('body').on('ajax:success','form.edit-form', (event,xhr,status) ->      editFormAjaxSuccess(event,xhr,status,$(this)))
  $('a#'+window.location.hash).click() if window.location.hash
  $('body').on('click','a.append-to-query-field', (event) ->               appendToQueryField(event,$(this)))
  $('body').on('click','a.write-to-query-field', (event) ->                writeToQueryField(event,$(this)))
  $('body').on('click','a.write-to-query-field-and-run-search', (event) -> writeToQueryFieldAndRunSearch(event,$(this)))
  $('body').on('click','a.clear-query-field', (event) ->                   clearQueryField(event,$(this)))
  $('body').on('click','a.instance-note-delete-link', (event) ->           deleteInstanceNote(event,$(this)))
  $('body').on('click','a.instance-note-cancel-delete-link', (event) ->    cancelDeleteInstanceNote(event,$(this)))
  #$('body').on('click','a#instance-note-create-link', (event) ->           instanceNoteCreate(event,$(this)))
  #$('body').on('click','a#instance-note-cancel-create-link', (event) ->    cancelInstanceNoteForm(event,$(this)))
  #$('body').on('click','a#instance-notes-switch-on-editing', (event) ->    instanceNotesSwitchOnEditing(event,$(this))) 
  #$('body').on('click','a#prevent-edit-instance-notes', (event) ->         instanceNotesSwitchOffEditing(event,$(this)))
  $('body').on('click','a.instance-note-cancel-edit-link', (event) ->      cancelInstanceNoteEdit(event,$(this)))
  $('body').on('change','.instance-note-key-id-select', (event) ->         instanceNoteKeyIdSelectChanged(event,$(this)))
  $('body').on('blur','.instance-note-value-text-area', (event) ->         instanceNoteValueTextAreaBlur(event,$(this)))
  $('body').on('click','a.clear-an-element', (event) ->                    clearAnElement(event,$(this))) 
  $('body').on('click','a.refresh-active-tab', (event) ->                  refreshActiveTab(event,$(this))) 
  $('body').on('click','.build-query-button', (event) ->                   buildQueryString(event,$(this)))
  $('body').on('click','.cancel-advanced-search-button', (event) ->        cancelAdvancedSearch(event,$(this)))
  $('#search-field').change (event) ->                                     searchFieldChanged(event,$(this))
  $('body').on('change','select#query-on', (event) ->                      queryonSelectChanged(event,$(this)))
  $('body').on('click','li.dropdown', (event) ->                           dropdownClick(event,$(this)))
  $('body').on('blur','li.dropdown', (event) ->                            dropdownBlur(event,$(this)))
  $('body').on('click','a.unconfirmed-delete-link', (event) ->             unconfirmedActionLinkClick(event,$(this)))
  $('body').on('click','a.unconfirmed-action-link', (event) ->             unconfirmedActionLinkClick(event,$(this)))
  $('body').on('click','a.cancel-link', (event) ->                         cancelLinkClick(event,$(this)))
  $('body').on('click','a.cancel-action-link', (event) ->                  cancelLinkClick(event,$(this)))
  #$('body').on('change','#name_name_type_id', (event) ->                   nameNameTypeIdChanged(event,$(this)))
  #$('body').on('change','#name_name_rank_id', (event) ->                   nameNameRankIdChanged(event,$(this)))
  $('body').on('click','#refresh-page-from-details-link', (event) ->       refreshPageLinkClick(event,$(this)))
  $('body').on('click','.refresh-page-link', (event) ->                    refreshPageLinkClick(event,$(this)))
  $('body').on('change','#name_name_rank_id', (event) ->                   nameRankIdChanged(event,$(this)))
  #$('body').on('change','#author-by-abbrev', (event) ->                    authorByAbbrevChanged(event,$(this)))
  #$('body').on('change','#ex-author-by-abbrev', (event) ->                 exAuthorByAbbrevChanged(event,$(this)))
  #$('body').on('change','#base-author-by-abbrev', (event) ->               baseAuthorByAbbrevChanged(event,$(this)))
  $('body').on('click','.cancel-new-record-link', (event) ->                cancelNewRecord(event,$(this)))
  $('body').on('click','#instance-reference-typeahead', (event) ->          $(this).select())
  $('body').on('click','.tree-row div.head', (event) ->                     treeRowClicked(event,$(this)))
  # new way
  #$('#apc-tree-component').on('change.nsl-tree',(event,data) ->             treeRowClicked2(event,$(this),data))

  #$('body').on('click','input.typeahead', (event) ->                        $(this).select())

  # When tabbing to search-result record, need to click to trigger retrieval of details.
  #$('#search-field').focus()
  $('a.show-details-link[tabindex]').focus (event) ->                      clickOnFocus(event,$(this))
  #$('body').on('click','a.show-details-link[tabindex]', (event) ->          clickOnFocus(event,$(this)))
  $('table.search-results tr td.takes-focus a.show-details-link[tabindex]').first().focus() 
  notice('End of fresh.js document ready.')

window.showInstanceWasCreated = (recordId,fromRecordType,fromRecordId) ->
  debug("showInstanceWasCreated: recordId: #{recordId}; fromRecordType: #{fromRecordType}; fromRecordId: #{fromRecordId}")

window.showRecordWasDeleted = (recordId,recordType) ->
  $("#search-result-details").addClass('hidden')
  $('#search-result-details').html('');
  $("#search-result-#{recordId}").addClass('hidden')

window.cancelNewRecord = (event,$element) ->
  debug('cancelNewRecord')
  $("#search-result-details").addClass('hidden')
  $("##{$element.attr('data-element-id')}").addClass('hidden')
  return false

refreshPageLinkClick = (event,$element) ->
  debug("refreshPageLinkClick")
  location.reload()

#authorByAbbrevChanged = (event,$element) ->
#debug("authorByAbbrev changed to: #{$element.val()};")
#setDependents('author-by-abbrev')

#exAuthorByAbbrevChanged = (event,$element) ->
#debug("exAuthorByAbbrev changed to: #{$element.val()};")
#setDependents('ex-author-by-abbrev')

#baseAuthorByAbbrevChanged = (event,$element) ->
#debug("baseAuthorByAbbrev changed to: #{$element.val()};")
#setDependents('base-author-by-abbrev')

window.setDependents = (fieldId) ->
  debug("setDependents for fieldId: #{fieldId}")
  fieldSelector = "##{fieldId}"
  fieldValue = $(fieldSelector).val()
  fieldValue = fieldValue.replace(/\s/g,'')
  if fieldValue == ''
    debug("setDependents: #{fieldId} is empty")
    $(".requires-#{fieldId}[value=='']").attr('disabled','true')
    $("input.requires-#{fieldId}").removeClass('enabled').addClass('disabled')
    $(".hide-if-#{fieldId}").removeClass('hidden')
  else
    debug("setDependents: #{fieldId} is not empty")
    $(".requires-#{fieldId}").removeAttr('disabled')
    $("input.requires-#{fieldId}").removeClass('disabled').addClass('enabled')
    $(".hide-if-#{fieldId}").addClass('hidden')

nameRankIdChanged = (event,$element) ->
  debug("nameRankId changed to: #{$element.val()} ")
  if $element.val() == ""
    debug("nameRankId is empty")
    $('.requires-rank').attr('disabled','true')
    $('input.requires-rank').removeClass('enabled').addClass('disabled')
    $('.hide-if-rank').removeClass('hidden')
  else
    debug("nameRankId is not empty")
    $('.requires-rank').removeAttr('disabled')
    $('input.requires-rank').removeClass('disabled').addClass('enabled')
    $('.hide-if-rank').addClass('hidden')

#nameNameTypeIdChanged = (event,$element) ->
#  debug("nameNameTypeIdChanged to: #{$element.val()} ")
#  $('#name-edit-tab').click()

#nameNameRankIdChanged = (event,$element) ->
# debug("nameNameRankIdChanged to: #{$element.val()} ")
# $('#name-edit-tab').click()

dropdownClick = (event,$element) ->
  debug("dropdownClick - showing")
  setTimeout (->
    hideSearchResultDetailsIfMenusOpen()
    return
  ), 600

dropdownBlur = (event,$element) ->
  debug("dropdownBlur - showing")
  setTimeout (->
    showSearchResultDetailsIfMenusClosed()
    return
  ), 600

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

cancelAdvancedSearch = (event,$element) ->
  debug('cancelAdvancedSearch')
  window.history.back()
  event.preventDefault()

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
 
clearAnElement = (event,$element) ->
  debug('clearAnElement')
  $($element.attr('data-target-element-selector')).text('')
  $($element.attr('data-show-this-element-selector')).removeClass('hidden')
  $($element.attr('data-hide-this-element-selector')).addClass('hidden')
  event.preventDefault()

instanceNoteKeyIdSelectChanged = (event,$element) ->
  debug('instanceNoteKeyIdSelectChanged')
  instanceNoteId = $element.attr('data-instance-note-id')
  instanceNoteEnableOrDisableSaveButton(event,$element,instanceNoteId)
  event.preventDefault()

instanceNoteValueTextAreaBlur = (event,$element) ->
  debug('instanceNoteValueTextAreaBlur')
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
 
refreshActiveTab = ->
  $('li.active a.tab').click()

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

writeToQueryField = (event,$element) ->
  $('#search-field').val($element.attr('data-value'))
  event.preventDefault()

writeToQueryFieldAndRunSearch = (event,$element) ->
  writeToQueryField(event,$element)
  $('#search-button').click()
  event.preventDefault()

editFormAjaxError = (event,xhr,status,$element) ->
  debug("editFormAjaxError: " + status)
  showFormFieldWasNotSaved($element)
  showFormErrorMessage(xhr,$element)
  return false
 
clickOnFocus = (event,$element) ->
  debug("clickOnFocus: id: #{$element.attr('id')}; event target: #{event.target}")
  $element.click()

editFormAjaxSuccess = (event,xhr,status,$element) ->
  debug('editFormAjaxSuccess')
  showFormFieldWasSaved($element)
  clearFormErrorMessage($element)
  return false

window.editFormFieldHasChanged = (event,$element) ->
  debug('editFormFieldHasChanged')
  showFieldIsNotYetSaved($element)
  $element.parents('form').submit()
  return false

showFieldIsNotYetSaved = ($element) ->
  $element.addClass('changed').addClass('not-saved')
  return

showFormFieldWasSaved = ($form) ->
  $form.find('.save-on-blur').removeClass('not-saved').addClass('saved')
  $form.find('.save-on-blur-checkbox').removeClass('not-saved').addClass('saved')
  debug('typeahead-field: '+$form.data('typeahead-field'))
  $('#' + $form.data('typeahead-field')).removeClass('not-saved').addClass('saved')
  return

showFormFieldWasNotSaved = ($form) ->
  $form.find('.save-on-blur').addClass('error')
  $('#' + $form.data('typeahead-field')).addClass('error')
  return
  
showFormErrorMessage = (xhr,$form) ->
  debug('showFormErrorMessage')
  $form.find('div.field-error-message').html(xhr.responseText)
  return

clearFormErrorMessage = ($form) ->
  $form.find('div.field-error-message').html('')
  return
  
# TODO: convert to using form submit?
querySimilarAuthorsForAuthor = (event,$element) ->
  debug('querySimilarAuthorsForAuthor start')
  url = $element.attr('data-url')
  $content = selectedRecords().first().closest('tr.search-result').find('td.main-content').html()
  debug("$content: #{$content}")
  url = url + '?query=' + jQuery.trim($content).replace(/&amp;/,'')
  window.location = 'http://' + location.host + url  
  return false

queryInstanceContext = (event,$element) ->
  debug('queryInstanceContext start')
  $selected = selectedRecords()
  debug($selected.length)
  $record = $selected.first().closest('tr.search-result')
  debug($record.attr('id'))
  recordId = $record.attr('data-record-id')
  recordType = $record.attr('data-record-type')
  url = $element.attr('data-url')
  debug("url: #{url}")
  url = url + '?query=instance-context:'+recordId
  debug("url: #{url}")
  window.location = 'http://' + location.host + url  
  return false

#TODO: URGENT: Remove hard-coded protocol.  e.g. Convert to form submit.
queryNameUsages = (event,$element) ->
  debug('queryNameUsages')
  $selected = selectedRecords()
  url = $element.attr('data-url')
  id = serializeSelectedIds()
  url = url + '?query=name-usages:'+id
  action =  $element.attr('data-action')
  window.location = 'http://' + location.host + url  
  return false

#TODO: URGENT: Remove hard-coded protocol.  e.g. Convert to form submit.
queryNameSynonymy = (event,$element) ->
  debug('queryNameSynonymy start')
  $selected = selectedRecords()
  url = $element.attr('data-url')
  id = serializeSelectedIds()
  url = url + '?query=name-synonymy:'+id
  debug("url: #{url}")
  action =  $element.attr('data-action')
  debug("action: #{action}")  
  window.location = 'http://' + location.host + url  
  return false


#TODO: Remove hard-coded protocol.  Convert to form submit?
queryRefInstances = (event,$element) ->
  debug('queryRefInstances start')
  $selected = selectedRecords()
  args = 'records='+serializeSelectedRecords()
  url = $element.attr('data-url')
  id = serializeSelectedIds()
  url = url + '?query=ref-instances:'+id
  action =  $element.attr('data-action')
  window.location = 'http://' + location.host + url  
  return false

#TODO: Remove hard-coded protocol.  Convert to form submit?
queryRefNames = (event,$element) ->
  debug('queryRefNames start')
  $selected = selectedRecords()
  args = 'records='+serializeSelectedRecords()
  url = $element.attr('data-url')
  id = serializeSelectedIds()
  url = url + '?query=ref-names:'+id
  action =  $element.attr('data-action')
  window.location = 'http://' + location.host + url  
  return false
  
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

querySet = ->
  $('#search-field').val("ids:#{serializeSelectedIds()}")
  $('.search-button').click()

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

changeNameCategoryOnEditTab = (event,inFocus,tabWasClicked) ->
  debug('change')
  debug(inFocus.attr('data-edit-url'))
  loadDetails(event,inFocus,tabWasClicked)

window.loadDetails = (event,inFocus,tabWasClicked = false) ->
  debug('window.loadDetails')
  $('#search-result-details').show()
  $('#search-result-details').removeClass('hidden')
  record_type = $('tr.showing-details').attr('data-record-type')
  instance_type = $('tr.showing-details').attr('data-instance-type')
  row_type = $('tr.showing-details').attr('data-row-type')
  tabIndex = $('.search-result.showing-details a[tabindex]').attr('tabindex')
  debug("tabIndex: #{tabIndex}")
  url = inFocus.attr('data-edit-url')+'?tab='+currentActiveTab(record_type)+'&tabIndex='+tabIndex+'&row-type='+row_type+'&instance-type='+instance_type+'&rowType='+inFocus.attr('data-row-type')
  debug("url: #{url}")
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
  debug("  recordCurrentActiveTab: #{$('ul.nav-tabs li.active a').attr('data-tab-name')}")
  $('body').attr('data-active-'+record_type+'-tab',$('ul.nav-tabs li.active a').attr('data-tab-name'))  
  
identifyDuplicates = (event,$this) ->
  debug('markDuplicates not implemented yet')
  false

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

selectInputContents = (event,$this) ->
  $this.select()
  return false
  
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

# window.hideToolsForOneThingSelected = ->
#   $('#toolbar a.show-when-one-thing-selected').addClass('hidden')
      
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

# Show the help, or hide it if already visible.
# Set up one-time event to hide popup if user clicks elsewhere on page.
togglePopUpHelp = (event,$this) ->
  clickPosition = $this.position()
  $this.attr('title','')  # intended to avoid messy display of tooltip while displaying help
  targetSelector = '#' + $this.attr('data-popup-id')
  $target = $(targetSelector + '.hidden')
  closeOpenPopups()
  if $target.hasClass('hidden')
    positionOnTheRight(clickPosition,$target,50)
    makeTargetVisible($target)
    setOneClickHider($target)
  false

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

toggleDetails = (event,$button) ->
  $target = $('div#search-result-details')
  if $target.hasClass('hidden')
    $target.removeClass('hidden')
    $('#toggle-details-btn').html('Hide Details')
  else
    $target.addClass('hidden')
    $('#toggle-details-btn').html('Show Details')

window.moveUpOneSearchResult = (startRow) -> 
  if startRow.prev()
    startRow.prev().find('a.show-details-link').focus()

window.moveDownOneSearchResult = (startRow) -> 
  startRow.next().find('a.show-details-link').focus()

window.moveToSearchResultDetails = (searchResultDetail,liElementHasClass) -> 
	$('#search-result-details ul li.'+liElementHasClass + ' a').focus()

