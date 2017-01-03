
workspaceParentNameSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/workspace/parent_name?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/workspace/parent_name?' +
                'allow_higher_ranks=' + $('#allow_higher_ranks:checked').length + '&' +
                'name_id=' + $('#workspace_parent_name_typeahead').attr('data-name-id') + '&' +
                'parent_name_id=' + $('#workspace_parent_name_typeahead').attr('data-parent-name-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/ -.*/,''))
        }
    },
    limit: 100
});

workspaceParentNameSuggestions.initialize();
