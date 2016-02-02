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
class Search::OnAuthor::FieldRule
  RULES = {
    "is-a-duplicate:"     => { where_clause: " duplicate_of_id is not null" },
    "is-not-a-duplicate:" => { where_clause: " duplicate_of_id is null" },
    "has-abbrev:"         => { where_clause: " abbrev is not null" },
    "has-no-abbrev:"      => { where_clause: " abbrev is null" },
    "has-name:"           => { where_clause: " name is not null" },
    "has-no-name:"        => { where_clause: " name is null" },
    "comments:"           => { trailing_wildcard: true,
                               leading_wildcard: true,
                               where_clause: " exists (select null from
                               comment where comment.author_id =
                               author.id and lower(comment.text)
                               like ?) " },

    "comments-by:"        => { where_clause: " exists (select null from
                               comment where comment.author_id =
                               author.id and lower(comment.created_by)
                               like ?) " },
    "full-name:"          => { leading_wildcard: true,
                               trailing_wildcard: true,
                               where_clause: "lower(full_name) like ?" },
    "name:"               => { tokenize: true,
                               where_clause:
                               " lower(f_unaccent(name))
                               like f_unaccent(?) " },
    "abbrev:"             => { tokenize: true,
                               where_clause:
                               " lower(f_unaccent(abbrev))
                               like f_unaccent(?) " },
    "name-or-abbrev:"     => { leading_wildcard: true,
                               trailing_wildcard: true,
                               tokenize: true,
                               where_clause: "lower(f_unaccent(name))
                               like f_unaccent(?) or
                               lower(f_unaccent(abbrev)) like f_unaccent(?) " },
    "name-exact:"         => { where_clause: "lower(name) like ?" },
    "abbrev-exact:"       => { where_clause: "lower(abbrev) like ?" },
    "full-name-exact:"    => { where_clause: "lower(full_name) like ?" },
    "comments-exact:"     => { where_clause: " exists (select null from
                               comment where comment.author_id = author.id
                               and lower(comment.text) like ?) " },
    "notes-exact:"        => { where_clause: " lower(notes) like ? " },
    "ipni-id:"            => { where_clause: "lower(ipni_id) like ?" },
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? ",
                               multiple_values_where_clause: " id in (?)" },
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ?",
                               multiple_values_where_clause: " id in (?)" },
    "duplicate-of-id:"    => { where_clause: "duplicate_of_id = ? " },

  }
end
