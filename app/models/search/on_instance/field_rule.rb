# frozen_string_literal: true
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
class Search::OnInstance::FieldRule
  RULES = {
    "id:"                   => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
    "ids:"                  => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
    "year:"                 => { where_clause: " exists (select null from
                                 reference ref where instance.reference_id =
                                 ref.id and ref.year = ?)" },
    "name:"                 => { where_clause: "exists (select null
                                 from name n
                                 where instance.name_id = n.id
                                 and lower(n.full_name) like ?)",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },
    "name-exact:"           => { where_clause: "exists (select null
                                 from name n
                                 where instance.name_id = n.id
                                 and lower(n.full_name) like ?)" },
    "comments:"             => { where_clause: " exists (select null from
                                 comment
                                 where comment.instance_id = instance.id
                                 and comment.text like ?) " },
    "comments-by:"          => { where_clause: " exists (select null
                                 from comment
                                 where comment.instance_id = instance.id
                                 and comment.created_by like ?) " },
    "page:"                 => { where_clause: " lower(page) like ?" },
    "page-qualifier:"       => { where_clause:
                                 " lower(page_qualifier) like ?" },
    "note-key:"             => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and lower(instance_note_key.name) like ?)) " },

    "notes-exact:"          => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and lower(instance_note.value) like ?) " },
    "verbatim-name-exact:"  => { where_clause:
                                 "lower(verbatim_name_string) like ?" },
    "verbatim-name:"        => { where_clause:
                                 "lower(verbatim_name_string) like ?",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },
    "notes:"                => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and lower(instance_note.value) like ?) ",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },

    "note-key-type-note:"   => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and lower(instance_note.value) like ?
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and lower(instance_note_key.name) = 'type')) ",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },

    "type:"                 => { where_clause: " exists (select null
                                 from instance_type
                                 where instance_type_id = instance_type.id
                                 and instance_type.name like ?) ",
                                 multiple_values: true,
                                 multiple_values_where_clause:
                                 " exists (select null
                                 from instance_type
                                 where instance_type_id = instance_type.id
                                 and instance_type.name in (?))",
                                 order: "name.full_name",
                                 join: :name },

    "ref-type:"             => { where_clause: " exists (select null
                                 from reference ref
                                 where ref.id = instance.reference_id
                                 and exists (select null
                                 from ref_type
                                 where ref_type.id = ref.ref_type_id
                                 and lower(ref_type.name) like lower(?)))",
                                 multiple_values: true,
                                 multiple_values_where_clause:
                                 " exists (select null from reference ref
                                 where ref.id = instance.reference_id
                                 and exists (select null from ref_type
                                 where ref_type.id = ref.ref_type_id
                                 and lower(ref_type.name) in (?)))" },
    "cites-an-instance:"    => { where_clause: " cites_id is not null" },

    "is-cited-by-an-instance:" => { where_clause: " cited_by_id is not null" },
    "does-not-cite-an-instance:" => { where_clause: " cites_id is null" },
    "is-not-cited-by-an-instance:" => { where_clause: " cited_by_id is null" },
    "verbatim-name-matches-full-name:" => { where_clause:
                                             " lower(verbatim_name_string) =
                                             (select lower(full_name)
                                             from name
                                             where name.id =
                                             instance.name_id) " },

    "verbatim-name-does-not-match-full-name:" =>
    { where_clause: " lower(verbatim_name_string) != (select lower(full_name)
    from name where name.id = instance.name_id) " },
    "is-novelty:" => { where_clause: " exists (select null
                       from instance_type
                       where instance_type_id = instance_type.id
                       and instance_type.primary_instance) " },
    "is-tax-nov-for-orth-var-name:" => { where_clause: " exists (select null
                                 from instance_type
                                 where instance_type_id = instance_type.id
                                 and instance_type.name = 'tax. nov.') and
                                         exists (select null from name where name.id = instance.name_id and exists (select null from name_status where name_status.id = name.name_status_id and name_status.name = 'orth. var.'))" },
    "species-or-below-syn-with-genus-or-above:" =>
    { where_clause:
      " instance.id in
      (
     SELECT i.id
  FROM instance i
 INNER JOIN instance ia
    ON i.cited_by_id = ia.id
 INNER JOIN name na
    ON ia.name_id = na.id
 INNER JOIN name_rank ra
    ON na.name_rank_id = ra.id
 INNER JOIN instance ib
    ON i.cites_id = ib.id
 INNER JOIN name nb
    ON ib.name_id = nb.id
 INNER JOIN name_rank rb
    ON nb.name_rank_id = rb.id
where rb.sort_order >= (select sort_order from name_rank where name = 'Species')
  and ra.sort_order <= (select sort_order from name_rank where name = 'Genus')
      )
      ",
      order: "name.full_name",
      join: :name },
    "rank:" => { where_clause: " exists (select null from
                  name n inner join name_rank nr
                  on n.name_rank_id = nr.id where instance.name_id =
                  n.id and lower(nr.name) like lower(?))",
                 order: "name.full_name" },

    "bad-relationships-974:" => { where_clause: " instance.id in (select syn.id
  from instance syn
 inner join instance standalone
    on syn.cited_by_id = standalone.id
 where syn.instance_type_id in (
    select id
      from instance_type
 where name in ('replaced synonym', 'basionym')
       )
   and standalone.instance_type_id not in (
    select id
      from instance_type
    where name in ('comb. nov.',
          'comb. et stat. nov.', 'nom. nov.', 'nom. et stat. nov.'
     )
       )
)", order: "instance.id" },
  }.freeze
end
