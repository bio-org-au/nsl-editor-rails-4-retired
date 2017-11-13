// Used on name edit form.
function setUpWorkspaceParentName() {

    $('#workspace_parent_name_typeahead').typeahead({highlight: true}, {
        name: 'workspace-parent-name-id',
        displayKey: function(obj) {
            return 'choice' + obj.value;
        },
        source: workspaceParentNameSuggestions.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh. Do not clear the hidden field on this event
            // because it will clear the field just by tabbing into the field.
        })
        .on('typeahead:selected', function($e,datum) {
            $('#workspace_parent_name_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#workspace_name_parent_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}
