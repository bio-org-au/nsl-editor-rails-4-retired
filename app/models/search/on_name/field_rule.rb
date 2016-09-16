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
class Search::OnName::FieldRule
  RULES = {
    "autonym-name-mismatch:" =>
    { where_clause:
      "id in (select name.id
  from name
 inner join name parent
    on name.parent_id = parent.id
 where name.full_name not like concat('%',parent.name_element)
   and name.id in
       (
    select id
      from name
    where name_type_id in (
        select id
          from name_type
    where autonym
       )
       )
      )" },
    "is-a-duplicate:" => { where_clause: " duplicate_of_id is not null", },
    "is-not-a-duplicate:" => { where_clause: " duplicate_of_id is null", },
    "is-a-parent:" =>
    { where_clause:
      " exists (select null from name child where child.parent_id = name.id) ", },

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

    "is-orth-var-and-sec-ref-first:" =>
    { where_clause:
      "ID IN (SELECT n.id
                FROM   instance i
                       INNER JOIN NAME n
                               ON i.name_id = n.id
                       INNER JOIN reference r
                               ON i.reference_id = r.id
                       INNER JOIN name_status ns
                               ON n.name_status_id = ns.id
                       INNER JOIN instance_type it
                               ON i.instance_type_id = it.id
                WHERE  it.secondary_instance
                       AND ns.NAME = 'orth. var.'
                       AND r.year = (SELECT Min(r2.year)
                                     FROM   reference r2
                                            INNER JOIN instance i2
                                                    ON r2.id = i2.reference_id
                                            INNER JOIN NAME n2
                                                    ON i2.name_id = n2.id
                                     WHERE  n2.id = n.id)
             ) ",
      allow_common_and_cultivar: true, },

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

    "id:" => { multiple_values: true,
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
      order: "case when parent_id is null then 'A' else 'B' end, full_name",
      allow_common_and_cultivar: true, },

    "name:" =>
    { where_clause: "lower(f_unaccent(full_name)) like f_unaccent(?) ",
      wildcard_embedded_spaces: true,
      trailing_wildcard: true, },

    "name-exact:" =>
    { where_clause: "lower(f_unaccent(full_name)) like f_unaccent(?) ", },

    "name-element:" =>
    { where_clause: "lower(f_unaccent(name_element)) like f_unaccent(?) ",
      leading_wildcard: true,
      trailing_wildcard: true, },

    "name-element-exact:" =>
    { where_clause: "lower(f_unaccent(name_element)) like f_unaccent(?) ", },

    "simple-name:" =>
    { where_clause: "lower(f_unaccent(simple_name)) like f_unaccent(?) ",
      leading_wildcard: true,
      trailing_wildcard: true, },

    "simple-name-exact:" =>
    { where_clause: "lower(f_unaccent(simple_name)) like f_unaccent(?) ", },

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

    "is-orth-var-and-non-primary-ref-first:" =>
    { where_clause:
      "ID IN (SELECT n.id
                FROM   instance i
                       INNER JOIN NAME n
                               ON i.name_id = n.id
                       INNER JOIN reference r
                               ON i.reference_id = r.id
                       INNER JOIN name_status ns
                               ON n.name_status_id = ns.id
                       INNER JOIN instance_type it
                               ON i.instance_type_id = it.id
                WHERE  not it.primary_instance
                       AND ns.NAME = 'orth. var.'
                       AND i.cites_id IS NULL
                       AND i.cited_by_id IS NULL
                       AND r.year = (SELECT Min(r2.year)
                                     FROM   reference r2
                                            INNER JOIN instance i2
                                                    ON r2.id = i2.reference_id
                                            INNER JOIN NAME n2
                                                    ON i2.name_id = n2.id
                                     WHERE  n2.id = n.id)
             ) ",
      allow_common_and_cultivar: true, },

    "is-orth-var-and-non-primary-sec-ref-first:" =>
    { where_clause:
      "ID IN (SELECT n.id
                FROM   instance i
                       INNER JOIN NAME n
                               ON i.name_id = n.id
                       INNER JOIN reference r
                               ON i.reference_id = r.id
                       INNER JOIN name_status ns
                               ON n.name_status_id = ns.id
                       INNER JOIN instance_type it
                               ON i.instance_type_id = it.id
                WHERE      NOT it.primary_instance
                       AND NOT it.secondary_instance
                       AND ns.NAME = 'orth. var.'
                       AND r.year = (SELECT Min(r2.year)
                                     FROM   reference r2
                                            INNER JOIN instance i2
                                                    ON r2.id = i2.reference_id
                                            INNER JOIN NAME n2
                                                    ON i2.name_id = n2.id
                                     WHERE  n2.id = n.id)
             ) ",
      allow_common_and_cultivar: true, },

    "with-exactly-one-instance:" =>
    { where_clause:
      "id in \
      (select name_id from instance group by name_id having count(*) = 1)", },

    "earliest-instance-not-primary:" =>
    { where_clause:
      "id in  (select n.id
  from name n
 inner join instance i
    on n.id = i.name_id
 inner join instance_type it
    on i.instance_type_id = it.id
 inner join reference r
    on i.reference_id = r.id
 inner join name_type nt
    on n.name_type_id = nt.id
 inner join name_status ns
    on n.name_status_id = ns.id
 where not (it.primary_instance or it.name in ('autonym','implicit autonym'))
   and nt.scientific
   and not ns.nom_inval
   and ns.name != 'isonym'
   and r.year = (select min(year)
                   from name n2
                  inner join instance i2
                     on n2.id = i2.name_id
                  inner join instance_type it2
                     on i2.instance_type_id = it2.id
                  inner join reference r2
                     on i2.reference_id = r2.id
                  where n2.id = n.id)
   and not exists (select null
                     from name n3
                    inner join instance i3
                       on n3.id = i3.name_id
                    inner join instance_type it3
                       on i3.instance_type_id = it3.id
                    inner join reference r3
                       on i3.reference_id = r3.id
                    where n3.id = n.id
                      and (it3.primary_instance or it3.name = 'autonym')
                      and r3.year = r.year)
      )", },

    "ref-title:" =>
    { where_clause:
      "exists (select null
                 from instance
                where instance.name_id = name.id
                  and exists (select null
                                from reference
                               where reference.id = instance.reference_id
                                 and lower(reference.title) like ?))", },

    "in-accepted-tree:" =>
    { where_clause:
      " exists (select null from accepted_name_vw where accepted_name_vw.id = name.id)" },

    "not-in-accepted-tree:" =>
    { where_clause:
      " not exists (select null from accepted_name_vw where accepted_name_vw.id = name.id)" },

    "bad-relationships-974:" => { where_clause: " name.id in
    (select name_id from instance where id in (select syn.cited_by_id
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
                   'comb. et stat. nov.',
                   'nom. nov.',
                   'nom. et stat. nov.')
       ) ) )", order: "name.sort_name" },
       "accepted-name-synonym-of-accepted-name:" => { where_clause: "id in
       (SELECT distinct n.id FROM name n
  JOIN tree_node nd ON nd.name_id = n.id
                       AND nd.type_uri_id_part = 'ApcConcept'
                       AND nd.next_node_id IS NULL
                       AND nd.checked_in_at_id is not null
  JOIN tree_arrangement a ON nd.tree_arrangement_id = a.id AND a.label = 'APC'
  JOIN instance i ON nd.instance_id = i.id
  JOIN instance s ON s.cited_by_id = i.id
  JOIN instance_type t ON s.instance_type_id = t.id
                      AND NOT t.misapplied and not t.pro_parte
  JOIN name sname ON s.name_id = sname.id
  JOIN tree_node snode ON s.name_id = snode.name_id
                          AND snode.next_node_id IS NULL
                          and snode.checked_in_at_id is not null
                          AND snode.tree_arrangement_id = a.id
                          AND snode.type_uri_id_part = 'ApcConcept') ",
                                                   order: "name.sort_name" },
    "name-synonym-of-itself:" => { where_clause: "  name.id in (
                                   select i.name_id
                                     from instance i
                                          inner join instance syn
                                          on i.id = syn.cited_by_id
                                          inner join instance i2
                                          on syn.cites_id = i2.id
                                          where i.name_id = i2.name_id)",
                                   order: "name.sort_name" },
    "name-is-double-synonym:" => { where_clause: "  name.id in (
    select name_id2
      from (
    select i2.name_id name_id2, i1.id i1_id,usage.cited_by_id,
          case t.misapplied
          when true then 'some sort of misapplication'
          else t.name
          end
      from instance i1
    inner join name n1
        on i1.name_id = n1.id
    inner join instance usage
        on i1.id = usage.cited_by_id
    inner join instance_type t
        on usage.instance_type_id = t.id
    inner join instance i2
        on usage.cites_id = i2.id
    inner join name n2
        on i2.name_id = n2.id
    group by i2.name_id, i1.id,usage.cited_by_id,
          case t.misapplied
          when true then 'some sort of misapplication'
          else t.name
       end
       ) grouped_by_misapplied
 group by name_id2, i1_id, cited_by_id
having count(*)   > 1)",
                                                   order: "name.sort_name" },
    "name-has-double-synonym:" => { where_clause: "  name.id in (
select name_id
  from instance
 where id in (
select i1_id
  from (
    select i2.name_id name_id2, i1.id i1_id,usage.cited_by_id,
          case t.misapplied
          when true then 'some sort of misapplication'
          else t.name
          end
      from instance i1
    inner join name n1
        on i1.name_id = n1.id
    inner join instance usage
        on i1.id = usage.cited_by_id
    inner join instance_type t
        on usage.instance_type_id = t.id
    inner join instance i2
        on usage.cites_id = i2.id
    inner join name n2
        on i2.name_id = n2.id
    group by i2.name_id, i1.id,usage.cited_by_id,
          case t.misapplied
          when true then 'some sort of misapplication'
          else t.name
       end
       ) grouped_by_misapplied
 group by name_id2, i1_id, cited_by_id
having count(*)   > 1
)
    )",
                                                   order: "name.sort_name" },

  }.freeze
end
