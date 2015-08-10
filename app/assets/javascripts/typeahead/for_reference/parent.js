
function setUpReferenceParent() {
    $('#reference-parent-typeahead').typeahead({highlight: true}, {
      name: 'reference-parent',
      displayKey: 'value',
      source: referenceByCitationForParent.ttAdapter()})
      .on('typeahead:selected', function($e,datum) {
        $('#reference_parent_id').val(datum.id);
      })
      .on('typeahead:autocompleted', function($e,datum) {
        $('#reference_parent_id').val(datum.id);
      })
      .on('typeahead:closed', function($e,datum) {
        // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
        // Users must select or autocomplete.
      });
}

