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
                               where_clause: " lower(taxon) like ?" },
    "taxon-no-wildcard:"  => { where_clause: " lower(taxon) like ?" },
    "taxon-with-syn:"      => { trailing_wildcard: true,
                               where_clause: " (lower(taxon) like ? and record_type = 'accepted') or (parent_id in (select id from orchids where lower(taxon) like ? and record_type = 'accepted'))",
                               order: "seq"},
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? ",
                               multiple_values_where_clause: " id in (?)" },
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ?",
                               multiple_values_where_clause: " id in (?)" },
    "id-with-syn:"        => { where_clause: "id = ? or parent_id = ?",
                               order: "seq"},
    "has-parent:"         => { where_clause: "parent_id is not null" },
    "has-no-parent:"      => { where_clause: "parent_id is null" },
    "is-accepted:"        => { where_clause: "record_type = 'accepted'" },
    "is-syn:"             => { where_clause: "record_type = 'synonym'" },
    "is-misapplied:"      => { where_clause: "record_type = 'misapplied'" },
    "is-hybrid-cross:"    => { where_clause: "record_type = 'hybrid_cross'" },
    "no-name-match:"      => { where_clause: "not exists (select null from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" },
    "some-name-match:"    => { where_clause: "exists (select null from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name))" },
    "many-name-match:"    => { where_clause: "1 <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" },
    "one-name-match:"     => { where_clause: "1 =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" },
    "name-match-no-primary:"     => { where_clause: "1 =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific and not exists (select null from instance join instance_type on instance.instance_type_id = instance_type.id where instance_type.primary_instance and name.id = instance.name_id)))" },
    "name-match-eq:"      => { where_clause: "? =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" },
    "name-match-gt:"      => { where_clause: "? <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" },
    "name-match-gte:"     => { where_clause: "? <=  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" },
    "partly:"             => { where_clause: "partly is not null"},
    "not-partly:"         => { where_clause: "partly is null"},
    "taxon-sharing-name-id:" => { where_clause: " id in (select orchid_id from orchids_names where name_id in (select name_id from orchids_names group by name_id having count(*) > 1))"},
    "has-preferred-name:"   => { where_clause: " exists (select null from orchids_names where orchids.id = orchids_names.orchid_id)"},
    "has-no-preferred-name:"   => { where_clause: " not exists (select null from orchids_names where orchids.id = orchids_names.orchid_id)"},
    "created-by:"=> { where_clause: "created_by = ?"},
    "updated-by:"=> { where_clause: "updated_by = ?"},
    "not-created-by:"=> { where_clause: "created_by != ?"},
    "not-created-by-batch:"=> { where_clause: "created_by != 'batch'"},
    "original-text:"=> { where_clause: "lower(original_text) like ?"},
    "original-text-has-×:"=> { where_clause: "lower(original_text) like '%×%'"},
    "original-text-has-x:"=> { where_clause: "lower(original_text) like '%×%'"},
    "hybrid-level:"=> { where_clause: "lower(hybrid_level) like ?"},
    "hybrid-level-has-value:"=> { where_clause: "hybrid_level is not null"},
    "hybrid-level-has-no-value:"=> { where_clause: "hybrid_level is null"},
    "hybrid:"=> { where_clause: "hybrid = ?"},
    "hybrid-has-value:"=> { where_clause: "hybrid is not null"},
    "hybrid-has-no-value:"=> { where_clause: "hybrid is null"},
    "alt-taxon-for-matching:"=> { where_clause: "lower(alt_taxon_for_matching) like ?"},
    "no-further-processing:"=> { where_clause: " exclude_from_further_processing or exists (select null from orchids kids where kids.parent_id = orchids.id and kids.exclude_from_further_processing) or exists (select null from orchids pa where pa.id = orchids.parent_id and pa.exclude_from_further_processing)",
                               order: "seq"},
  }.freeze
end
