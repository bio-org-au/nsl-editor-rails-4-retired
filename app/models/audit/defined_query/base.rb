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
class Audit::DefinedQuery::Base

  attr_reader :results, :limited, :common_and_cultivar_included, :has_relation, :relation, :count

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def debug(s)
    tag = "Audit::DefinedQuery::Base #{s}"
    #puts("#{tag}: #{s}")
    Rails.logger.debug("#{tag}: #{s}")
  end
 
  def run_query(parsed_request)
    debug("")
    debug("parsed_request.where_arguments: #{parsed_request.where_arguments}")
    debug("parsed_request.defined_query_arg: #{parsed_request.defined_query_arg}")
    debug("parsed_request.count: #{parsed_request.count}")
    debug("parsed_request.limit: #{parsed_request.limit}")
    if parsed_request.count
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      debug("run_query counting")
      list_query = Audit::DefinedQuery::ListQuery.new(parsed_request.as_a_list_request)
      @has_relation = false
      @relation = nil
      @results = list_query.results
      @limited = list_query.limited
      @common_and_cultivar_included = list_query.common_and_cultivar_included
      @count = @results.size
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      debug("@count: #{@count}")
      @results = []
    else
      debug("query listing")
      list_query = Audit::DefinedQuery::ListQuery.new(parsed_request)
      @has_relation = false
      @relation = nil
      @results = list_query.results
      @limited = list_query.limited
      @common_and_cultivar_included = list_query.common_and_cultivar_included
      @count = @results.size
    end
  end
end


