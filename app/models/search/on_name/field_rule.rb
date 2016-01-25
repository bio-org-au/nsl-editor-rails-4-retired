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
class Search::OnName::FieldRule
  RULES = {
    "is-a-duplicate:" => { where_clause: " duplicate_of_id is not null", },
    "is-not-a-duplicate:" => { where_clause: " duplicate_of_id is null", },
    "is-a-parent:" =>
    { where_clause:
      " exists (select null from name child where child.parent_id = name.id) ",
    },

    "is-not-a-parent:" =>
    { where_clause:
      " not exists \
      (select null from name child where child.parent_id = name.id) ", },

    "has-no-parent:" => { where_clause: " parent_id is null", },
    "has-parent:" => { where_clause: " parent_id is not null", },
    "is-a-child:" => { where_clause: " parent_id is not null", },
    "is-not-a-child:" => { where_clause: " parent_id is null", },

    "has-a-second-parent:" =>
    { where_clause: " second_parent_id is not null", },

    "has-no-second-parent:" => { where_clause: " second_parent_id is null", },

    "is-a-second-parent:" =>
    { where_clause:
      " exists \
      (select null from name child where child.second_parent_id = name.id) ", },

    "is-not-a-second-parent:" =>
    { where_clause:
      " not exists \
      (select null from name child where child.second_parent_id = name.id) ", },

    "has-no-instances:" =>
    { where_clause:
      " not exists (select null from instance i where i.name_id = name.id)", },

    "has-instances:" =>
    { where_clause:
      " exists (select null from instance i where i.name_id = name.id)", },

    "is-orth-var-with-no-orth-var-instances:" =>
    { where_clause:
      " name_status_id = (select id \
      from name_status ns \
      where ns.name = 'orth. var.') \
      and not exists \
      (select null from instance i \
      where i.name_id = name.id \
      and i.instance_type_id = \
      (select id \
      from instance_type ity \
      where ity.name = 'orthographic variant'))", },

    "comments:" =>
    { trailing_wildcard: true,
      leading_wildcard: true,
      where_clause: " exists (select null from comment \
      where comment.name_id = name.id and comment.text like ?) ", },

    "comments-exact:" =>
    { where_clause:
      " exists \
      (select null \
      from comment \
      where comment.name_id = name.id and comment.text like ?) ", },

    "comments-by:" =>
    { where_clause:
      " exists \
      (select null \
      from comment \
      where comment.name_id = name.id and comment.created_by like ?) ", },

    "id:"                   => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 allow_common_and_cultivar: true,
                                 multiple_values_where_clause: " id in (?)" },

    "author-id:" => { where_clause: "author_id = ? ", },
    "base-author-id:" => { where_clause: "base_author_id = ? ", },
    "ex-base-author-id:" => { where_clause: "ex_base_author_id = ? ", },
    "ex-author-id:" => { where_clause: "ex_author_id = ? ", },
    "sanctioning-author-id:" => { where_clause: "sanctioning_author_id = ? ", },
    "duplicate-of-id:" => { where_clause: "duplicate_of_id = ?", },

    "parent-id:" => { where_clause: "id = ? or parent_id = ?",
                      allow_common_and_cultivar: true, },

    "second-parent-id:" => { where_clause: "id = ? or second_parent_id = ? ",
                             allow_common_and_cultivar: true, },

    "master-id:" => { where_clause: "id = ? or duplicate_of_id = ?", },

    "parent-or-second-parent-id:" =>
    { where_clause: "id = ? or parent_id = ? or second_parent_id = ? ",
      order: "case when parent_id is null then 'A' else 'B' end, citation",
      allow_common_and_cultivar: true, },

    "name:" =>
    { where_clause: "lower(f_unaccent(full_name)) like f_unaccent(?) ",
      leading_wildcard: true,
      trailing_wildcard: true, },

    "name-exact:" =>
    { where_clause: "lower(f_unaccent(full_name)) like f_unaccent(?) ", },

    "rank:" =>
    { where_clause:
      "name_rank_id in (select id from name_rank where lower(name) like ?)",
      multiple_values: true,
      multiple_values_where_clause:
      "name_rank_id in (select id from name_rank where lower(name) in (?))", },

    "type:" =>
    { where_clause:
      "name_type_id in (select id from name_type where lower(name) like ?)",
      allow_common_and_cultivar: true,
      multiple_values: true,
      multiple_values_where_clause:
      "name_type_id in (select id from name_type where lower(name) in (?))", },

    "status:" =>
    { where_clause:
      "name_status_id in \
      (select id from name_status where lower(name) like ?)",
      multiple_values: true,
      multiple_values_where_clause:
      "name_status_id in (select id from name_status where lower(name) in (?))", },
 
    "below-rank:" =>
    { where_clause:
      "name_rank_id in \
      (select id from name_rank where sort_order > (select sort_order from \
      name_rank the_nr where lower(the_nr.name) like ?))", },

    "above-rank:" =>
    { where_clause:
      "name_rank_id in (select id from name_rank where sort_order < (select \
      sort_order from name_rank the_nr where lower(the_nr.name) like ?))", },

    "author:" =>
    { where_clause:
      "author_id in (select id from author where lower(abbrev) like ?)", },

    "ex-author:" =>
    { where_clause:
      "ex_author_id in (select id from author where lower(abbrev) like ?)", },

    "base-author:" =>
    { where_clause:
      "base_author_id in (select id from author where lower(abbrev) like ?)", },

    "ex-base-author:" =>
    { where_clause:
      "ex_base_author_id in \
      (select id from author where lower(abbrev) like ?)", },

    "sanctioning-author:" =>
    { where_clause:
      "sanctioning_author_id in \
      (select id from author where lower(abbrev) like ?)", },

    "comments-but-no-instances:" =>
    { where_clause:
      "exists (select null from comment where comment.name_id = name.id \
      and comment.text like ?) and not exists \
      (select null from instance where name_id = name.id)", },
  }
end
