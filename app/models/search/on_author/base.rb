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
# Search on Author
class Search::OnAuthor::Base
  attr_reader :results,
              :limited,
              :info_for_display,
              :rejected_pairings,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :id,
              :count

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def run_query(parsed_request)
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
    end
  end

  def run_count_query(parsed_request)
    debug('#run_count_query')
    count_query = Search::OnAuthor::CountQuery.new(parsed_request)
    @has_relation = true
    @relation = count_query.sql
    @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @rejected_pairings = []
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
  end

  def run_list_query(parsed_request)
    debug('#run_list_query')
    list_query = Search::OnAuthor::ListQuery.new(parsed_request)
    @has_relation = true
    @relation = list_query.sql
    @results = relation.all
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @rejected_pairings = []
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    @count = @results.size
  end

  def debug(s)
    Rails.logger.debug("Search::OnAuthor::Base: #{s}")
  end
end
