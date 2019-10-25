
console.log('start');
function setUpOrchidParentTypeahead() {
        $("#orchid-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-orchid-id-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: orchidParentSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('parent typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              debug('parent typeahead:selected');
              $('#orchid_parent_id').val(datum.id);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              debug('parent typeahead:autocompeted');
                $('#orchid_parent_id').val(datum.id) })
        ;
}
console.log('end');

