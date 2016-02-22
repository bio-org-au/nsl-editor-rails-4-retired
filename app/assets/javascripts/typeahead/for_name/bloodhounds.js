
nameDuplicateSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/name/duplicate?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/name/duplicate?' +
                'name_id=' + $('#duplicate-of-typeahead').attr('data-name-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))
        }
    },
    limit: 100
});

nameDuplicateSuggestions.initialize();


window.nameByFullName = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: window.relative_url_root + '/names/typeahead_on_full_name?term=%QUERY',
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
nameByFullName.initialize();

//---------------------------------------------------------------------------------------------------------------//

// Provides a way to inject the current name id into the URL.
// Using the replace function to strip off the Name's rank, which
// is delimited by a pipe symbol (|).
nameParentSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/names/name_parent_suggestions?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/names/name_parent_suggestions?' +
                'name_id=' + $('#name-parent-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))
        }
    },
    limit: 100
});

nameParentSuggestions.initialize();


//---------------------------------------------------------------------------------------------------------------//


// Provides a way to inject the current name id into the URL.
nameParentSuggestionsForHybrid = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/name/hybrid_parent?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/name/hybrid_parent?' +
                'name_id=' + $('#name-parent-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))
        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
nameParentSuggestionsForHybrid.initialize();


//---------------------------------------------------------------------------------------------------------------//


// Provides a way to inject the current name id into the URL.
nameParentSuggestionsForCultivar = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/name/cultivar_parent?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/name/cultivar_parent?' +
                'name_id=' + $('#name-parent-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))
        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
nameParentSuggestionsForCultivar.initialize();


