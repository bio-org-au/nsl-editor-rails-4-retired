function setUpReferenceDuplicateOf() {
    $('#reference-duplicate-of-typeahead').typeahead({highlight: true}, {
      name: 'reference-duplicate-of-id',
      displayKey: 'value',
      source: referenceByCitationForDuplicate.ttAdapter()})
      .on('typeahead:selected', function($e,datum) {
				 $('#reference_duplicate_of_id').val(datum.id);
			})
      .on('typeahead:autocompleted', function($e,datum) {
				 $('#reference_duplicate_of_id').val(datum.id);
			})
      .on('typeahead:closed', function($e,datum) {
        // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
        // Users must select or autocomplete.
      });
}

