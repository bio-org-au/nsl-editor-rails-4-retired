
function setUpAuthorDuplicateOfTypeahead() {
   $('#author-duplicate-of-typeahead').typeahead({highlight: true}, {
        name: 'Authors',
        displayKey: 'value',
        source: authorsByNameDuplicateOf.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
          $('#author_duplicate_of_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
          $('#author_duplicate_of_id').val(datum.id);
        })
}

