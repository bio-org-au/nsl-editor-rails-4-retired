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
class Instance::AsTypeahead::ForNameShowingReferences
  attr_reader :references

  def initialize(params)
    @references = []
    unless params[:instance_id].blank?
      @references = Reference.find_by_sql(["select i.id,r.citation,r.year, r.pages, r.source_system, t.name instance_type from reference r  " \
                                          " inner join author a on r.author_id = a.id " \
                                          " inner join instance i on r.id = i.reference_id " \
                                          " inner join instance_type t on i.instance_type_id = t.id " \
                                          " where i.name_id = (select name_id from instance where id = ?)" \
                                          "   and i.id != ? " \
                                          "   and lower(r.citation) like lower('%'||?||'%') " \
                                          " order by r.year,a.name",
                                           params[:instance_id].to_i, params[:instance_id].to_i, params[:term]])
                             .collect { |ref| { value: "#{ref.citation}:#{ref.year} #{'[' + ref.pages + ']' unless ref.pages_useless?} #{'[' + ref.instance_type + ']' unless ref.instance_type == 'secondary reference'} #{'[' + ref.source_system.downcase + ']' unless ref.source_system.blank?}", id: ref.id } }
    end
  end
end
