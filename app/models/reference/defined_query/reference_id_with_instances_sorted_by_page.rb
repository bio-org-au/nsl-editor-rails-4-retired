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
#   A defined query is one that the Search class knows about and may
#   instantiate.
class Reference::DefinedQuery::ReferenceIdWithInstancesSortedByPage
  attr_reader :results,
              :limited,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :count,
              :show_csv,
              :total

  def initialize(parsed_request)
    @parsed_request = parsed_request
    run_query
  end

  def debug(s)
    tag = "Reference::DefinedQuery::ReferenceIdWithInstancesSortedByPage"
    Rails.logger.debug("#{tag}: #{s}")
  end

  def run_query
    @show_csv = false
    if @parsed_request.count
      run_count_query
    else
      run_list_query
    end
    @total = nil
  end

  def run_count_query
    query = Search::OnReference::ListQuery.new(@parsed_request)
    @relation = query.sql # TODO: work out how to provide the relation and sql
    results = relation.all
    @limited = query.limited
    debug(results.size)
    @count = results.size
    results.each do |ref|
      @count += ref.instances.size
    end
    @common_and_cultivar_included = query.common_and_cultivar_included
  end

  def run_list_query
    @results = Instance.ref_usages(@parsed_request.where_arguments,
                                   @parsed_request.limit.to_i,
                                   "page")
    @limited = false
    @common_and_cultivar_included = true
    @count = @results.size
    @has_relation = false
    @relation = nil
  end

  def csv?
    @show_csv
  end
end
