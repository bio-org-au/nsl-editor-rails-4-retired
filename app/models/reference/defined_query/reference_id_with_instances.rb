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
#   A defined query is one that the Search class knows about and may
#   instantiate.
class Reference::DefinedQuery::ReferenceIdWithInstances
  attr_reader :results,
              :limited,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :count,
              :show_csv,
              :total

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def debug(s)
    tag = "Reference::DefinedQuery::ReferenceIdWithInstances"
    Rails.logger.debug("#{tag}: #{s}")
  end

  def inspect_query(parsed_request)
    debug("")
    debug("where_arguments: #{parsed_request.where_arguments}")
    debug("defined_query_arg: #{parsed_request.defined_query_arg}")
    debug("count: #{parsed_request.count}")
    debug("limit: #{parsed_request.limit}")
  end

  def run_query(parsed_request)
    inspect_query(parsed_request)
    @show_csv = false
    @relation = nil
    @has_relation = false
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
    end
    @total = nil
  end

  def run_count_query(parsed_request)
    debug("run_count_query")
    ref = Reference.find(parsed_request.where_arguments)
    @count = ref.instances.size + 1
    @results = []
    @limited = false
    @common_and_cultivar_included = true
  end

  def run_list_query(parsed_request)
    debug("listing with limit: #{parsed_request.limit}")
    query = Reference::DefinedQuery::ReferenceIdWithInstancesQuery.new(
      parsed_request,
      "name"
    )
    @results = query.results
    @limited = false; # name_query.limited
    @common_and_cultivar_included = true
    @count = @results.size
  end

  def csv?
    @show_csv
  end
end
