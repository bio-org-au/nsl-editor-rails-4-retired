
function setUpInstanceName() {

    $('#instance-name-typeahead').typeahead({highlight: true}, {
        name: 'name-typeahead',
        displayKey: 'value',
        source: nameByFullName.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh.
        })
        .on('typeahead:selected', function($e,datum) {
            $('#instance_name_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#instance_name_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

