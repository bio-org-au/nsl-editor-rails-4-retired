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

# Used when Search::Error needs to be returned.
class Search::Error
  attr_reader :empty,
              :error,
              :error_message,
              :executed_query,
              :more_allowed,
              :parsed_request

  def initialize(params)
    Rails.logger.debug("Search::Error start with query string: #{params[:query_string]}")
    Rails.logger.debug("#{'=' * 40}")
    @parsed_request = Search::ParsedRequest.new(params)
    @common_and_cultivar_included = true
    @count = false
    @empty = false
    @error = true
    @tree = false
    @limited = false
    @query_string = params[:query_string]
    @query_target = params[:query_target]
    @more_allowed = false
    @executed_query = Search::EmptyExecutedQuery.new(params)
    @error_message = params[:error_message]
   end

  def to_history
    { "query_string" => @query_string, "query_target" => @query_target, "result_size" => 0, "time_stamp" => Time.now, "error" => true, "error_message" => @error_message }
  end
end
