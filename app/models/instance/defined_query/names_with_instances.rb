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
class Instance::DefinedQuery::NamesWithInstances 

  attr_reader :limited,
              :common_and_cultivar_included,
              :results 

  def initialize(parsed_request)
    @tag = "Instance::DefinedQuery::NamesWithInstances"
    run_query(parsed_request)
  end

  # Instances of a name algorithm starts here.
  def self.name_instances(name_search_string,limit = 100,apply_limit = true)
    logger.debug(%Q(-- Name.name_instances search for "#{name_search_string}" with limit: #{limit}))
    names = []
    results = []
    names,
        rejected_pairings,
        limited,
        focus_anchor_id,
        info = Name::AsSearchEngine.search(name_search_string,limit,false,true,apply_limit)
    names.each do |name|
      if name.instances.size > 0
        results.concat(Instance::AsSearchEngine.name_usages(name.id))
      end
    end
    results
  end

  def debug(s)
    puts("#{@tag}: #{s}")
    Rails.logger.debug("#{@tag}: #{s}")
  end
 
  def run_query(parsed_request)
    debug("")
    debug("parsed_request.where_arguments: #{parsed_request.where_arguments}")
    debug("parsed_request.defined_query_arg: #{parsed_request.defined_query_arg}")
    debug("parsed_request.count: #{parsed_request.count}")
    debug("parsed_request.limit: #{parsed_request.limit}")
    if parsed_request.count
      debug("run_query counting")
      name_query = Search::OnName::ListQuery.new(parsed_request)
      relation = name_query.sql
      results = relation.all
      limited = name_query.limited

      debug(results.size)
      tally = results.size
      results.each  do | name |
        debug(name.id)
        tally += name.instances.size
      end
      debug("tally: #{tally}")

      @limited = limited
      @common_and_cultivar_included = name_query.common_and_cultivar_included
    else
      debug("run_query listing")
      name_query = Search::OnName::Base.new(parsed_request)
      debug(name_query.results.size)
      results = []
      name_query.results.each  do | name |
        debug(name.id)
        results.concat(Instance::AsSearchEngine.name_usages(name.id))
      end
      debug("results.size: #{results.size}")
      @limited = name_query.limited
      @common_and_cultivar_included = name_query.common_and_cultivar_included
      @results = results
    end
  end



end


