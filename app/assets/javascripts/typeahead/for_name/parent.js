function setUpNameParentTypeahead() {
    if (typeof(nameParentSuggestions) != "undefined") {
        $("#name-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-name-id-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: nameParentSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('parent typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              debug('parent typeahead:selected');
              $('#name_parent_id').val(datum.id);
              $('#name_family_id').val(datum.family_id);
              $("#name-family-typeahead").typeahead('val', datum.family_value);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              debug('parent typeahead:autocompeted');
                $('#name_parent_id').val(datum.id) })
        ;
    };
}

