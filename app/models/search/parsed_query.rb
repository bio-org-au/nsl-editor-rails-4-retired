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
class Search::ParsedQuery

  attr_reader :params, :query_string, :count, :list, :limit, :target_table, :common_and_cultivar, :order, :canonical_query_string, :where_arguments
  DEFAULT_LIST_LIMIT = 100

  def initialize(params)
    Rails.logger.debug("Search::ParsedQuery start: params: #{params}")
    @params = params
    #@auery_string = @params['query_string']
    #Rails.logger.debug("Search::ParsedQuery initialize: @query_string: #{@query_string}")
    parse_query_string
  end

  def parse_query_string
    Rails.logger.debug("Search::ParsedQuery parse_query_string start: @params: #{@params}")
    @query_string = @params['query_string']
    Rails.logger.debug("Search::ParseQueryString @query_string: #{@query_string}")
    remaining_tokens = @query_string.split(/ /)
    remaining_tokens = parse_count_or_list(remaining_tokens)
    remaining_tokens = parse_limit(remaining_tokens)
    remaining_tokens = parse_target_table(remaining_tokens)
    remaining_tokens = parse_common_and_cultivar(remaining_tokens)
    remaining_tokens = parse_order(remaining_tokens)
    remaining_tokens = gather_where_arguments(remaining_tokens)
  end

  def parse_count_or_list(tokens)
    if tokens.first.match(/count/i)
      tokens = tokens.drop(1)
      @count = true
      @list = !@count
    elsif tokens.first.match(/list/i)
      tokens = tokens.drop(1)
      @list = true
      @count = !@list
    else 
      @list = true
      @count = !@list
    end
    tokens
  end

  def parse_limit(tokens)
    if tokens.blank?
      @limit = DEFAULT_LIST_LIMIT
    elsif tokens.first.match(/^\d+$/)
      @limit = tokens.first.to_i
      tokens = tokens.drop(1)
    else 
      @limit = DEFAULT_LIST_LIMIT
    end
    tokens
  end

  def parse_target_table(tokens)
    @target_table = 'name'
    tokens
  end
  
  def parse_common_and_cultivar(tokens)
    @common_and_cultivar = false
    tokens
  end
  
  def parse_order(tokens)
    @order = 'lower(full_name)'
    tokens
  end

  def gather_where_arguments(tokens)
    @where_arguments = tokens.join(' ')
    tokens
  end
  
  def canonical_query_string
    @params[:query_string]
  end

end



