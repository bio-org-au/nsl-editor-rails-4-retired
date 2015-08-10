function setUpReferenceAuthor() {
   $('#reference-author-typeahead').typeahead({highlight: true}, {
        name: 'Authors',
        displayKey: 'value',
        source: authorsByName.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
          $('#reference_author_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
          $('#reference_author_id').val(datum.id);
        })
}

