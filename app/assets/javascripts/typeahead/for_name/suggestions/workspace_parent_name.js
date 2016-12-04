
workspaceParentNameSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/workspace/parent_name?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/workspace/parent_name?' +
                'name_id=' + $('#workspace-parent-name-typeahead').attr('data-name-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/ -.*/,''))
        }
    },
    limit: 100
});

workspaceParentNameSuggestions.initialize();
