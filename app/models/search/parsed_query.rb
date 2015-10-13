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

  attr_reader :params, :query_string, :count, :list, :limited, :limit, :target_table, :common_and_cultivar, :order, :canonical_query_string, :id, 
    :where_arguments, :defined_query, :defined_query_arg
  DEFAULT_LIST_LIMIT = 100
  MAX_LIST_LIMIT = 1000
  NO_LIST_LIMIT = -1
  DEFINED_QUERIES = {
    'instances-for-name-id:' => true,
    'instances-for-name:' => true,
    'instances-for-ref-id:' => true,
    'instances-for-ref-id-sort-by-page:' => true
  }

  def initialize(params)
    Rails.logger.debug("Search::ParsedQuery start: params: #{params}")
    @params = params
    parse_query_string
  end

  def parse_query_string
    Rails.logger.debug("Search::ParsedQuery parse_query_string start: @params: #{@params}")
    @query_string = @params['query_string'].gsub(/  */,' ')
    Rails.logger.debug("Search::ParseQueryString @query_string: #{@query_string}")
    # Before splitting on spaces, make sure every colon has at least one space after it.
    remaining_tokens = @query_string.strip.gsub(/:/,': ').gsub(/:  /,': ').split(/ /)
    remaining_tokens = parse_count_or_list(remaining_tokens)
    remaining_tokens = parse_limit(remaining_tokens)
    remaining_tokens = parse_defined_query(remaining_tokens)
    unless @defined_query
      remaining_tokens = parse_target_table(remaining_tokens)
      remaining_tokens = parse_common_and_cultivar(remaining_tokens)
      remaining_tokens = parse_order(remaining_tokens)
      remaining_tokens = gather_where_arguments(remaining_tokens)
    end
  end

  def parse_defined_query(tokens)
    Rails.logger.debug("Search::ParsedQuery parse_defined_query start: tokens: #{tokens.join(',')}")
    if DEFINED_QUERIES.has_key?(tokens.first)
      @defined_query = tokens.first
      @defined_query_arg = tokens.drop(1).join(' ')
      tokens = []
    else
      @defined_query = false  
    end
    tokens
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
    @limited = @list
    if tokens.blank?
      @limit = DEFAULT_LIST_LIMIT
    elsif tokens.first.match(/^\d+$/)
      # Safeguard
      @limit = tokens.first.to_i > MAX_LIST_LIMIT ? MAX_LIST_LIMIT : tokens.first.to_i
      tokens = tokens.drop(1)
    elsif tokens.first.match(/\Aall\z/i)
      #@limit = NO_LIST_LIMIT
      #@limited = false
      @limit = MAX_LIST_LIMIT 
      tokens = tokens.drop(1)
    else 
      @limit = DEFAULT_LIST_LIMIT
    end
    tokens
  end

  def parse_target_table(tokens)
    default_table = 'name'
    if tokens.blank?
      @target_table = default_table
    else
      case tokens.first
      when /\Aauthors{0,1}\z/i
        @target_table = 'author'
        tokens = tokens.drop(1)
      when /\Ainstances{0,1}\z/i
        @target_table = 'instance'
        tokens = tokens.drop(1)
      when /\Anames{0,1}\z/i
        @target_table = 'name'
        tokens = tokens.drop(1)
      when /\Areferences{0,1}\z/i
        @target_table = 'reference'
        tokens = tokens.drop(1)
      when /\Arefs{0,1}\z/i
        @target_table = 'reference'
        tokens = tokens.drop(1)
      else
        @target_table = default_table
      end
    end
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



