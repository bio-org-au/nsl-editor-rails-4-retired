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
    "one-taxon-with-syn:" => { trailing_wildcard: false,
                               where_clause: " lower(taxon) like ? or parent_id = (select id from orchids where lower(taxon) like ?)" },
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? ",
                               multiple_values_where_clause: " id in (?)" },
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ?",
                               multiple_values_where_clause: " id in (?)" },
    "id-with-syn:"        => { where_clause: "id = ? or parent_id = ?" },
    "is-syn:"             => { where_clause: "parent_id is not null" },
    "is-not-syn:"         => { where_clause: "parent_id is null" },
    "no-name-match:"      => { where_clause: "not exists (select null from name where taxon = name.simple_name)" },
    "some-name-match:"    => { where_clause: "exists (select null from name where taxon = name.simple_name)" },
    "many-name-match:"    => { where_clause: "1 <  (select count(*) from name where taxon = name.simple_name)" },
    "one-name-match:"     => { where_clause: "1 =  (select count(*) from name where taxon = name.simple_name)" },
    "name-match-eq:"      => { where_clause: "? =  (select count(*) from name where taxon = name.simple_name)" },
    "name-match-gt:"      => { where_clause: "? <  (select count(*) from name where taxon = name.simple_name)" },
    "name-match-gte:"     => { where_clause: "? <=  (select count(*) from name where taxon = name.simple_name)" },
  }.freeze
end
