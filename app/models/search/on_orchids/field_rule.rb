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
class Search::OnOrchids::FieldRule
  RULES = {
    "taxon:"              => { trailing_wildcard: true,
                               where_clause: " lower(taxon) like ?",
                                      order: "seq"},
    "taxon-no-wildcard:"  => { where_clause: " lower(taxon) like ?",
                                      order: "seq"},
    "taxon-with-syn:"      => { trailing_wildcard: true,
                               where_clause: " (lower(taxon) like ? and record_type = 'accepted' and not doubtful) or (parent_id in (select id from orchids where lower(taxon) like ? and record_type = 'accepted' and not doubtful))",
                               order: "seq"},
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? ",
                               multiple_values_where_clause: " id in (?)",
                                      order: "seq"},
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ?",
                               multiple_values_where_clause: " id in (?)",
                                      order: "seq"},
    "id-with-syn:"        => { where_clause: "id = ? or parent_id = ?",
                               order: "seq"},
    "has-parent:"         => { where_clause: "parent_id is not null",
                                      order: "seq"},
    "has-no-parent:"      => { where_clause: "parent_id is null",
                                      order: "seq"},
    "is-accepted:"        => { where_clause: "record_type = 'accepted'",
                                      order: "seq"},
    "is-syn:"             => { where_clause: "record_type = 'synonym'",
                                      order: "seq"},
    "is-misapplied:"      => { where_clause: "record_type = 'misapplied'",
                                      order: "seq"},
    "is-hybrid-cross:"    => { where_clause: "record_type = 'hybrid_cross'",
                                      order: "seq"},
    "no-name-match:"      => { where_clause: "not exists (select null from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "some-name-match:"    => { where_clause: "exists (select null from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name))" ,
                                      order: "seq"},
    "many-name-match:"    => { where_clause: "1 <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "one-name-match:"     => { where_clause: "1 =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "name-match-no-primary:"     => { where_clause: "1 =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific and not exists (select null from instance join instance_type on instance.instance_type_id = instance_type.id where instance_type.primary_instance and name.id = instance.name_id)))",
                                      order: "seq"},
    "name-match-eq:"      => { where_clause: "? =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "name-match-gt:"      => { where_clause: "? <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "name-match-gte:"     => { where_clause: "? <=  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "partly:"             => { where_clause: "partly is not null",
                                      order: "seq"},
    "not-partly:"         => { where_clause: "partly is null",
                                      order: "seq"},
    "taxon-sharing-name-id:" => { where_clause: " id in (select orchid_id from orchids_names where name_id in (select name_id from orchids_names group by name_id having count(*) > 1))",
                                      order: "seq"},
    "has-preferred-name:"   => { where_clause: " exists (select null from orchids_names where orchids.id = orchids_names.orchid_id)",
                                      order: "seq"},
    "has-no-preferred-name:"   => { where_clause: " not exists (select null from orchids_names where orchids.id = orchids_names.orchid_id)"},
    "created-by:"=> { where_clause: "created_by = ?",
                                      order: "seq"},
    "updated-by:"=> { where_clause: "updated_by = ?",
                                      order: "seq"},
    "not-created-by:"=> { where_clause: "created_by != ?",
                                      order: "seq"},
    "not-created-by-batch:"=> { where_clause: "created_by != 'batch'",
                                      order: "seq"},
    "original-text:"=> { where_clause: "lower(original_text) like ?",
                                      order: "seq"},
    "original-text-has-×:"=> { where_clause: "lower(original_text) like '%×%'",
                                      order: "seq"},
    "original-text-has-x:"=> { where_clause: "lower(original_text) like '%×%'",
                                      order: "seq"},
    "hybrid-level:"=> { where_clause: "lower(hybrid_level) like ?",
                                      order: "seq"},
    "hybrid-level-has-value:"=> { where_clause: "hybrid_level is not null",
                                      order: "seq"},
    "hybrid-level-has-no-value:"=> { where_clause: "hybrid_level is null",
                                      order: "seq"},
    "hybrid:"=> { where_clause: "hybrid = ?",
                                      order: "seq"},
    "hybrid-has-value:"=> { where_clause: "hybrid is not null",
                                      order: "seq"},
    "hybrid-has-no-value:"=> { where_clause: "hybrid is null",
                                      order: "seq"},
    "alt-taxon-for-matching:"=> { where_clause: "lower(alt_taxon_for_matching) like ?",
                                      order: "seq"},
    "no-further-processing:"=> { where_clause: " exclude_from_further_processing or exists (select null from orchids kids where kids.parent_id = orchids.id and kids.exclude_from_further_processing) or exists (select null from orchids pa where pa.id = orchids.parent_id and pa.exclude_from_further_processing)",
                               order: "seq"},
    "is-isonym:"=> { where_clause: "isonym is not null",
                                      order: "seq"},
    "is-orth-var:"=> { where_clause: "name_status like 'orth%'",
                                      order: "seq"},
    "name-status:"=> { where_clause: "name_status like ?",
                       leading_wildcard: true,
                       trailing_wildcard: true,
                       order: "seq"},
    "notes:"=> { where_clause: "lower(notes) like ?",
                       leading_wildcard: true,
                       trailing_wildcard: true,
                       order: "seq"},
    "rank:"         => { where_clause: "lower(rank) like ?",
                                      order: "seq"},
    "rank-is-null:"         => { where_clause: "rank is null",
                                      order: "seq"},
    "is-doubtful:"=> { where_clause: "doubtful",
                                      order: "seq"},
    "is-not-doubtful:"=> { where_clause: "doubtful",
                                      order: "seq"},
    "excluded-with-syn:"   => { trailing_wildcard: true,
                           where_clause: " (lower(taxon) like ? and record_type = 'accepted' and doubtful) or (parent_id in (select id from orchids where lower(taxon) like ? and record_type = 'accepted' and doubtful))",
                               order: "seq"},

  }.freeze
end
