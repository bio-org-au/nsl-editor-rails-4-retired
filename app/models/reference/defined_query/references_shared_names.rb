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
class Reference::DefinedQuery::ReferencesSharedNames
  attr_reader :results,
              :limited,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :count,
              :show_csv,
              :results_array

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def debug(s)
    tag = "Reference::DefinedQuery::ReferencesSharedNames"
    Rails.logger.debug("#{tag}: #{s}")
  end

  def run_query(parsed_request)
    debug("")
    debug("parsed_request.where_arguments: #{parsed_request.where_arguments}")
    debug("parsed_request.defined_query_arg: #{parsed_request.defined_query_arg}")
    debug("parsed_request.count: #{parsed_request.count}")
    debug("parsed_request.limit: #{parsed_request.limit}")
    args = parsed_request.where_arguments.split(",")
    fail "Exactly 2 reference IDs are expected." unless args.size == 2
    ref_id_1 = args.first.to_i
    ref_id_2 = args.last.to_i
    fail "No Reference exists for ID:#{args.first}" unless Reference.exists?(ref_id_1)
    fail "No Reference exists for ID:#{args.last}" unless Reference.exists?(ref_id_2)
    @show_csv = false
    if parsed_request.count
      debug("counting")
      instances = Instance.for_ref(ref_id_1).for_ref_and_correlated_on_name_id(ref_id_2)
      @count = instances.size
      @results = []
      @limited = false
      @common_and_cultivar_included = true
      @has_relation = false
      @relation = nil
    else
      debug("listing with limit: #{parsed_request.limit}")
      @results = Instance.for_ref(ref_id_1).for_ref_and_correlated_on_name_id(ref_id_2).order_by_name_full_name.limit(parsed_request.limit)
      @limited = true
      @common_and_cultivar_included = true
      @count = @results.size
      @has_relation = false
      @relation = nil
      @results_array = @results
    end
  end

  def csv?
    @show_csv
  end
end
