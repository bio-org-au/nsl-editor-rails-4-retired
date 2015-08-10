function setUpInstanceInstanceForNameShowingReferenceUpdate() {

    $('#instance-instance-for-name-showing-reference-typeahead').typeahead({highlight: true}, {
        name: 'instance-instance-for-name-showing-reference-typeahead',
        displayKey: 'value',
        source: instanceForNameShowingReferenceUpdate.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh.
            // Do not clear the hidden field on this event
            // because it will clear the field just by tabbing 
            // into the field.
            // $('#instance_cites_id').val('');
        })
        .on('typeahead:selected', function($e,datum) {
            $('#instance_cites_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#instance_cites_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

