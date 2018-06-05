function setUpNameFamilyTypeahead() {
    if (typeof(nameFamilySuggestions) != "undefined") {
        $("#name-family-typeahead").typeahead({highlight: true}, {
            name: "familys",
            displayKey: function (obj) {
                return obj.value;
            },
            source: nameFamilySuggestions.ttAdapter()
        })
            .on('typeahead:opened', function ($e, datum) {
                debug('typeahead:opened');
            })
            .on('typeahead:selected', function ($e, datum) {
                debug('typeahead:selected');
                $('#name_family_id').val(datum.id)
            })
            .on('typeahead:autocompleted', function ($e, datum) {
                debug('typeahead:autocompeted');
                $('#name_family_id').val(datum.id)
            })
        ;
    }
    ;
}

