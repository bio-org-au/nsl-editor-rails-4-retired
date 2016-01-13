// main.js

  jQuery.ajaxSetup({  
      'beforeSend': function (xhr) {xhr.setRequestHeader("Accept", "text/javascript")}  
  });

  function reportError(s) {
    try {
      console.log('Error: ' + s);
    }
    catch(e) {
    }
  }

// ====================================== //
//  Document Ready                        //
// ====================================== //
 $(document).ready(function() {
   debug('Start of main.js document ready.');

  /* save editable fields automatically */
  $('a.add-to-query').click(function(event) {
	  debug('a.add-to-query clicked');
	  var val = $('#query').val();
	  $('#query').val(val + ' ' + $(this).attr('data-search-component'));
	  $('#query').focus();
  });

  // simulate clicking on and giving focus to the designated thing e.g. the first row of search results
  // tried these in coffee script without success
  //$('td.text.give-me-focus').click();
  $('td.text.give-me-focus').focus();
	
	$('#show-tabindexes').click(function(event) {
		showTabindexes();
		return(false);
	});

  // http://stackoverflow.com/questions/2196641/how-do-i-make-jquery-contains-case-insensitive-including-jquery-1-8
  // "I would do something like this"
  $.expr[':'].containsIgnoreCase = function (n, i, m) {
        return jQuery(n).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0;
  };
  debug('End of main.js document ready.');
});  // end of document ready
// ===================================  end of document ready ================================================


var masterCheckboxClicked = function masterCheckboxClicked(event,$this) {
  debug('masterCheckboxClicked');
  var checked = $('div#search-results *.stylish-checkbox-checked').length;
  if (checked == 0 ) {
    // nth checked, so check everything
    $this.removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
    $('div#search-results *.stylish-checkbox-unchecked').removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
  } else {
    // sth checked, so uncheck everything
    $this.removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
    $('div#search-results *.stylish-checkbox-checked').removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
  }
};

var showTabindexes = function showTabIndexes() {
  $('.tabindex-display').remove();
  $.each($('[tabindex]'),function(index,value) {
	debug('index: ' + index + '; value: ' + value + '; ' + $(value).attr('tabindex'));
	$(value).append('<span class="tabindex-display">(' + $(value).attr('tabindex') + ') </span>');
  });
};

// var querySet = function querySet() {
//  debug('querySet');
//  var $selected = $('tr.search-result td.checkbox-container .stylish-checkbox-checked');
//  var queryIds = 'ids:';
//  $selected.each(function(index) {
//    queryIds += $(this).closest('tr.search-result[data-record-id]').attr('data-record-id')+',';
//  });
//   $('#query').val(queryIds.substring(0, queryIds.length - 1));
//   $('.search-button').click();
// }
// 

var refreshCitation = function refreshCitation() {
	$('.citation').load($('.citation').attr('data-refresh-path'));
};

var identifyDuplicates = function 	identifyDuplicates(event) {
  debug('identifyDuplicates');
};

  // Credit: http://jonstjohn.com/node/23
  //
  // Not currently using due to limitations.
  // Current limitations:
  // 1. Stops page loads only, not ajax actions which might also discard unsaved data.  Resolve by adding custom code.
  // 2. Stays on once set, even if errors have been fixed and data saved.  Resolve: custom code to account for errors and switch off appropriately.
  //
  // Maybe not feasible in phase 1.
	function setConfirmUnload(on) {
	  window.onbeforeunload = (on) ? unloadMessage : null;
	}

	function unloadMessage() {
	  return 'You have entered new data on this page.  If you navigate away from this page without first saving your data, the changes will be lost.';
	}
