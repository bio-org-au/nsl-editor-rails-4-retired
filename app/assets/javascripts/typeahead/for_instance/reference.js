
function setUpInstanceReference() {
    $('#instance-reference-typeahead').typeahead(
        {highlight: true},
        {
        name: 'instance-reference',
        displayKey: 'value',
        source: referenceByCitation.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
            $('#instance_reference_id').val(datum.id);
            })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select.
        });
}


