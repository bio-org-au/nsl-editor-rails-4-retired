// Used on name edit form.
function setUpNameDuplicateOf() {

    $('#duplicate-of-typeahead').typeahead({highlight: true}, {
        name: 'name-duplicate-of-id',
        displayKey: 'value',
        source: nameDuplicateSuggestions.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh. Do not clear the hidden field on this event
            // because it will clear the field just by tabbing into the field.
        })
        .on('typeahead:selected', function($e,datum) {
            $('#name_duplicate_of_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#name_duplicate_of_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

