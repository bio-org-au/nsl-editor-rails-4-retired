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
class Name::DefinedQuery::NamesWithInstances 

  attr_reader :results, :limited, :common_and_cultivar_included, :has_relation, :relation, :count

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def debug(s)
    tag = "Name::DefinedQuery::NamesWithInstances"
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
      query = Search::OnName::ListQuery.new(parsed_request)
      @relation = query.sql  # TODO: work out how to provide the relation and sql
      results = relation.all
      limited = query.limited

      debug(results.size)
      tally = results.size
      results.each  do | name |
        tally += 1
        debug("tallying for #{name.id}")
        tally += name.instances.size
        debug("tally: #{tally}")
      end
      debug("tally: #{tally}")

      @limited = limited
      @common_and_cultivar_included = query.common_and_cultivar_included
      @count = tally
    else
      debug("run_query listing")
      query = Search::OnName::Base.new(parsed_request)
      debug(query.results.size)
      results = []
      @limited = false
      query.results.each  do | name |
        results.concat(Instance::AsSearchEngine.name_usages(name.id))
        if results.size >= parsed_request.limit
          @limited = true
          break
        end
      end
      debug("results.size: #{results.size}")
      @limited = query.limited
      @common_and_cultivar_included = query.common_and_cultivar_included
      @results = results
      @count = results.size
      @has_relation = false
      @relation = nil
    end
  end

end


