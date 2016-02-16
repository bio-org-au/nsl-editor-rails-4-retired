#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Field rules available for building predicates.
class Search::OnReference::FieldRule
  RULES = {
    "is-a-duplicate:"       => { where_clause: " duplicate_of_id is not null" },
    "is-not-a-duplicate:"   => { where_clause: " duplicate_of_id is null" },
    "is-a-parent:"          => { where_clause: " exists (select null from
                                 reference child where child.parent_id =
                                 reference.id) " },
    "is-not-a-parent:"      => { where_clause: " not exists (select null from
                                 reference child where child.parent_id =
                                 reference.id) " },
    "has-no-children:"      => { where_clause: " not exists (select null from
                                 reference child where child.parent_id =
                                 reference.id) " },
    "has-no-parent:"        => { where_clause: " parent_id is null" },
    "is-a-child:"           => { where_clause: " parent_id is not null" },
    "is-not-a-child:"       => { where_clause: " parent_id is null" },
    "is-published:"         => { where_clause: " published" },
    "is-not-published:"     => { where_clause: " not published" },

    "author-exact:"         => { where_clause: " author_id in (select id from
                                 author where lower(name) like ?)" },
    "citation-exact:"       => { where_clause: " lower(citation) like ?" },

    "comments:"             => { trailing_wildcard: true,
                                 leading_wildcard: true,
                                 where_clause: " exists (select null from
                                 comment where comment.reference_id =
                                 reference.id and lower(comment.text)
                                 like ?) " },

    "comments-by:"          => { where_clause: " exists (select null from
                                 comment where comment.reference_id =
                                 reference.id and comment.created_by
                                 like ?) " },
    "edition:"              => { where_clause: " lower(edition) like ?" },
    "publication-date:"     => { where_clause: " lower(publication_date)
                                 like ?" },
    "type:"                 => { multiple_values: true,
                                 where_clause: " ref_type_id in (select id
                                 from ref_type where lower(name) like ?)",
                                 multiple_values_where_clause: " ref_type_id
                                 in (select id from ref_type where lower(name)
                                 in (?))" },
    "author-role:"          => { where_clause: " ref_author_role_id in
                                 (select id from ref_author_role where
                                 lower(name) like ?)" },
    "title-exact:"          => { where_clause: " lower(title) like ?" },
    "isbn:"                 => { where_clause: " lower(isbn) like ?" },
    "issn:"                 => { where_clause: " lower(issn) like ?" },
    "published-location:"   => { where_clause: " lower(published_location)
                                 like ?" },
    "publisher:"            => { where_clause: " lower(publisher) like ?" },
    "volume:"               => { where_clause: " lower(volume) like ?" },
    "bhl:"                  => { where_clause: " lower(bhl_url) like ?" },
    "doi:"                  => { where_clause: " lower(doi) like ?" },
    "tl2:"                  => { where_clause: " lower(tl2) like ?" },

    "id:"                   => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
    "ids:"                  => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
    "author-id:"            => { multiple_values: true,
                                 where_clause: " author_id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
    "year:"                 => { multiple_values: true,
                                 where_clause: " year = ? ",
                                 multiple_values_where_clause: " id in (?)" },
    "after-year:"           => { where_clause: " year > ? " },
    "before-year:"          => { where_clause: " year < ? " },
    "duplicate-of-id:"      => { multiple_values: true,
                                 where_clause: " duplicate_of_id = ?",
                                 multiple_values_where_clause:
                                 " duplicate_of_id in (?)" },

    "parent-id:"            => { where_clause: " id = ? or parent_id = ?",
                                 order: "case when parent_id is null then
                                 'A' else 'B' end, citation" },

    "master-id:"            => { where_clause: " id = ? or
                                 duplicate_of_id = ?" },

    "citation-text:"        => { scope_: "search_citation_text_for" },

    "citation:"             => { trailing_wildcard: true,
                                 leading_wildcard: true,
                                 tokenize: true,
                                 where_clause: " lower(citation) like ? " },

    "author:"               => { trailing_wildcard: true,
                                 leading_wildcard: true,
                                 where_clause: "author_id in
                                 (select id from author where lower(name)
                                 like ?)" },

    "title:"                => { trailing_wildcard: true,
                                 where_clause: " lower(title) like ? " },

    "parent-ref-wrong-child-type:" => { where_clause: "reference.id in (
select r.id
from reference r
inner join
ref_type rt
on r.ref_type_id = rt.id
inner join
reference child
on r.id = child.parent_id
inner join
ref_type child_rt
on child.ref_type_id = child_rt.id
where (rt.name,child_rt.name) not in
(select xrt.name, xcrt.name
from ref_type xrt
inner join
ref_type xcrt
on xrt.id = xcrt.parent_id))" },
  }
end
