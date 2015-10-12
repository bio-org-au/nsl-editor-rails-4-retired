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
class Search::OnAuthor::Base

  attr_reader :results, :limited, :info_for_display, :rejected_pairings, :common_and_cultivar_included, :sql, :id

  def initialize(parsed_query)
    run_query(parsed_query)
  end

  def run_query(parsed_query)
    Rails.logger.debug('Search::OnAuthor::Base#run_query')
    if parsed_query.count
      Rails.logger.debug('Search::OnAuthor::Base#run_query counting')
      count_query = Search::OnAuthor::CountQuery.new(parsed_query)
      @sql = count_query.sql
      @results = sql.count
      Rails.logger.debug("Search::OnAuthor::Base#run_query results: #{@results}")
      @limited = false
      @info_for_display = count_query.info_for_display
      @rejected_pairings = []
      @common_and_cultivar_included = count_query.common_and_cultivar_included
    else
      list_query = Search::OnAuthor::ListQuery.new(parsed_query)
      @sql = list_query.sql
      @results = sql.all
      @limited = list_query.limited
      @info_for_display = list_query.info_for_display
      @rejected_pairings = []
      @common_and_cultivar_included = list_query.common_and_cultivar_included
    end
  end

end



