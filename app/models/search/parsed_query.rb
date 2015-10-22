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

  attr_reader :canonical_query_string, 
              :common_and_cultivar, 
              :count, 
              :defined_query, 
              :defined_query_arg,
              :id, 
              :limit, 
              :limited, 
              :list, 
              :order, 
              :params, 
              :query_string, 
              :target_table, 
              :where_arguments,
              :query_target

  DEFAULT_LIST_LIMIT = 100
  MAX_LIST_LIMIT = 1000
  NO_LIST_LIMIT = -1
  DEFINED_QUERIES = {
    'instance-name-id:' => 'instances-for-name-id:',
    'instances-for-name-id:' => 'instances-for-name-id:',
    'instance-name:' => 'instances-for-name:',
    'instances-for-name:' => 'instances-for-name:',
    'instance-ref-id:' => 'instances-for-ref-id:',
    'instances-for-ref-id:' => 'instances-for-ref-id:',
    'instance-ref-id-sort-by-page:' => 'instances-for-ref-id-sort-by-page:',
    'instances-for-ref-id-sort-by-page:' => 'instances-for-ref-id-sort-by-page:'
  }

  TARGETS = {
    'author' => 'author',
    'authors' => 'author',
    'instance' => 'instance',
    'instances' => 'instance',
    'name' => 'name',
    'names' => 'name',
    'reference' => 'reference',
    'references' => 'reference',
    'ref' => 'reference',
    'tree' => 'tree',
  }

  DEFAULT_TARGET = 'name'

  def initialize(params)
    Rails.logger.debug("Search::ParsedQuery start: params: #{params}")
    @params = params
    parse_query
  end

  def parse_query
    Rails.logger.debug("Search::ParsedQuery parse_query start: ===============================")
    Rails.logger.debug("Search::ParsedQuery parse_query start: @params: #{@params}")
    @query_string = @params['query_string'].gsub(/  */,' ')
    Rails.logger.debug("Search::ParseQueryString @query_string: #{@query_string}")
    @query_target = (@params['query_target']||'').sub(/Search /,'').sub(/s *$/,'').strip.downcase
    Rails.logger.debug("Search::ParseQueryString @query_target: #{@query_target}")
    # Before splitting on spaces, make sure every colon has at least one space after it.
    remaining_tokens = @query_string.strip.gsub(/:/,': ').gsub(/:  /,': ').split(/ /)
    remaining_tokens = parse_count_or_list(remaining_tokens)
    remaining_tokens = parse_limit(remaining_tokens)
    remaining_tokens = parse_target(remaining_tokens)
    remaining_tokens = parse_defined_query(remaining_tokens)
    unless @defined_query
      remaining_tokens = parse_common_and_cultivar(remaining_tokens)
      remaining_tokens = parse_order(remaining_tokens)
      remaining_tokens = gather_where_arguments(remaining_tokens)
    end
  end

  def query_target_valid?
    TARGETS.has_key?(@query_target)
  end

  def parse_defined_query(tokens)
    Rails.logger.debug("Search::ParsedQuery parse_defined_query start: tokens: #{tokens.join(',')}")
    if DEFINED_QUERIES.has_key?("#{@target_table}-#{tokens.first}")
      @defined_query = DEFINED_QUERIES["#{@target_table}-#{tokens.first}"]
      @defined_query_arg = tokens.drop(1).join(' ')
      tokens = []
    elsif DEFINED_QUERIES.has_key?("#{@target_table}-#{@params[:defined_query]}")
      @defined_query = DEFINED_QUERIES["#{@target_table}-#{@params[:defined_query]}"]
      @defined_query_arg = tokens.join(' ')
      tokens = []
    elsif DEFINED_QUERIES.has_key?(tokens.first)
      @defined_query = DEFINED_QUERIES[tokens.first]
      @defined_query_arg = tokens.drop(1).join(' ')
      tokens = []
    else
      @defined_query = false  
    end
    tokens
  end

  def parse_count_or_list(tokens)
    if tokens.blank?
      @list = true
      @count = !@list
    elsif tokens.first.match(/count/i)
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

  def parse_target(tokens)
    if query_target_valid?
      @target_table = TARGETS[@query_target]
      if TARGETS.has_key?(tokens.first)
        Rails.logger.info("Search::ParsedQuery parse_target discarding string target: #{tokens.first}")
        raise "Two search targets specified."
        tokens = tokens.drop(1)
      end
    elsif tokens.blank?
      @target_table = DEFAULT_TARGET
    elsif TARGETS.has_key?(tokens.first)
      @target_table = TARGETS[tokens.first]
        tokens = tokens.drop(1)
    else
      @target_table = DEFAULT_TARGET
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



