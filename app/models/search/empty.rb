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
class Search::Empty

  attr_reader :canonical_query_string, 
              :common_and_cultivar, 
              :common_and_cultivar_included,
              :count, 
              :empty, 
              :error, 
              :info_for_display, 
              :limit, 
              :limited, 
              :order, 
              :params, 
              :query_string, 
              :query_string_for_more, 
              :rejected_pairings, 
              :results, 
              :target_table, 
              :where_arguments,
              :more_allowed,
              :defined_query,
              :error_message,
              :count_allowed,
              :sql

  def initialize(params)
    Rails.logger.debug("Search::Empty start")
    Rails.logger.debug("#{'=' * 40}")
    @params = params
    @canonical_query_string = ''
    @common_and_cultivar = ''
    @common_and_cultivar_included= false
    @count = false
    @empty = true
    @error = false
    @info_for_display = ''
    @limit = 0
    @limited = false
    @order = ''
    @params = {}
    @query_string = ''
    @rejected_pairings = []
    @results = []
    @target_table = ''
    @where_arguments = ''
    @query_string_for_more = ''
    @more_allowed = false
    @defined_query = false
    @error_message = ''
    @count_allowed = false
  end

  def to_history
    ''
  end

end



