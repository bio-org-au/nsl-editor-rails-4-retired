// Get a list of references in instances of the name
instanceForNameShowingReference = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/instances/for_name_showing_reference?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/instances/for_name_showing_reference?name_id=' +
                $('#instance_name_id').val() +
                '&term=' + query
                //$('#instance-instance-for-name-showing-reference-typeahead').val().replace(/%/,'%25')
        }
    },
    limit: 100
});
 
// kicks off the loading/processing of `local` and `prefetch`
instanceForNameShowingReference.initialize();

// Get a list of instances for a name
instanceForSynonymy = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/instances/for_synonymy?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/instances/for_synonymy?name_id=' +
                $('#instance-name-id').val() +
                '&term=' + query
        }
    },
    limit: 100
}); 

// kicks off the loading/processing of `local` and `prefetch`
instanceForSynonymy.initialize();


// Get a list of references in instances of the name
instanceForNameShowingReferenceUpdate = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/instances/for_name_showing_reference?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/instances/for_name_showing_reference_to_update_instance?instance_id=' +
                $('#instance_id').val() +
                '&term=' + encodeURIComponent(query)
        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
instanceForNameShowingReferenceUpdate.initialize();

$(document).ready(function() {

window.authorsByName = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: window.relative_url_root + '/authors/typeahead_on_name?term=%QUERY',
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
authorsByName.initialize();

// constructs the suggestion engine
window.authorsByNameDuplicateOf = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/authors/typeahead/on_name/exclude/current?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/authors/typeahead/on_name/duplicate_of/' + 
                                                       $('#author-duplicate-of-typeahead').attr('data-excluded-id') +
                                                       '?term='+encodeURIComponent(query)
           }
          },
  limit: 100
});
 

// kicks off the loading/processing of `local` and `prefetch`
authorsByNameDuplicateOf.initialize();

authorsByAbbrev = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: window.relative_url_root + '/authors/typeahead_on_abbrev?term=%QUERY',
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
authorsByAbbrev.initialize();

// constructs the suggestion engine
window.referenceByCitation = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: window.relative_url_root + '/references/typeahead/on_citation?term=%QUERY',
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
referenceByCitation.initialize();


// constructs the suggestion engine
window.referenceByCitationForDuplicate = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/references/typeahead/on_citation/for_duplicate/?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/references/typeahead/on_citation/for_duplicate/' + 
                                                       $('#reference-duplicate-of-typeahead').attr('data-excluded-id') +
                                                       '?term='+encodeURIComponent(query)
           }
          },
  limit: 100
});
 
referenceByCitationForDuplicate.initialize();


// constructs the suggestion engine
window.referenceByCitationForParent = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/references/typeahead/on_citation/for_parent/?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/references/typeahead/on_citation/for_parent?id=' + 
                                                       $('#reference-parent-typeahead').attr('data-current-id') +
                                                       '&ref_type_id=' + $('#reference_ref_type_id').val() +
                                                       '&term='+encodeURIComponent(query) 
           }
          },
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
referenceByCitationForParent.initialize();


// constructs the suggestion engine
window.referenceByCitationExcludingCurrent = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/references/typeahead/on_citation/exclude/current?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/references/typeahead/on_citation/exclude/' + 
                                                       $('#instance-reference-typeahead').attr('data-excluded-id') +
                                                       '?term='+encodeURIComponent(query)
           }
          },
  limit: 100
});
 
referenceByCitationExcludingCurrent.initialize();

});
