
//---------------------------------------------------------------------------------------------------------------//

// Provides a way to inject the current orchid id into the URL.
// Using the replace function to strip off the Name's rank, which
// is delimited by a pipe symbol (|).
orchidParentSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/orchids/parent_suggestions?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/orchids/parent_suggestions?' +
                'orchid_id=' + $('#orchid-parent-typeahead').attr('data-orchid-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))
        }
    },
    limit: 100
});

orchidParentSuggestions.initialize();

