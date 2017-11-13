// main.js

jQuery.ajaxSetup({
    'beforeSend': function (xhr) {
        xhr.setRequestHeader('Accept', 'text/javascript');
    }
});

function reportError(s) {
    try {
        console.log('Error: ' + s);
    }
    catch (e) {
    }
}

// ====================================== //
//  Document Ready                        //
// ====================================== //
$(document).ready(function () {
    debug('Start of main.js document ready.');

    /* save editable fields automatically */
    $('a.add-to-query').click(function (event) {
        debug('a.add-to-query clicked');
        var val = $('#query').val();
        $('#query').val(val + ' ' + $(this).attr('data-search-component'));
        $('#query').focus();
    });

    // Simulate clicking on and giving focus to the designated thing
    // e.g. the first row of search results
    // Tried these in coffee script without success
    // $('td.text.give-me-focus').click();
    $('td.text.give-me-focus').focus();

    $('#show-tabindexes').click(function (event) {
        showTabIndexes();
        return (false);
    });

    // http://stackoverflow.com/questions/2196641/how-do-i-make-jquery-
    // contains-case-insensitive-including-jquery-1-8
    // "I would do something like this"
    $.expr[':'].containsIgnoreCase = function (n, i, m) {
        return jQuery(n).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0;
    };

    debug('End of main.js document ready.');
});  // end of document ready
// ===================================  end of document ready ================================================

var masterCheckboxClicked = function masterCheckboxClicked(event, $this) {
    debug('masterCheckboxClicked');
    var checked = $('div#search-results *.stylish-checkbox-checked').length;
    if (checked === 0) {
        // nth checked, so check everything
        $this.removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
        $('div#search-results *.stylish-checkbox-unchecked').removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
    } else {
        // sth checked, so uncheck everything
        $this.removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
        $('div#search-results *.stylish-checkbox-checked').removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
    }
};

var showTabIndexes = function showTabIndexes() {
    $('.tabindex-display').remove();
    $.each($('[tabindex]'), function (index, value) {
        debug('index: ' + index + '; value: ' + value + '; ' + $(value).attr('tabindex'));
        $(value).append('<span class="tabindex-display">(' + $(value).attr('tabindex') + ') </span>');
    })
};

