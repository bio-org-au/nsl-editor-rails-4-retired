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
class Search::ParsedRequest

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
              :query_target,
              :target_button_text,
              :count_allowed

  DEFAULT_LIST_LIMIT = 100
  MAX_LIST_LIMIT = 1000
  NO_LIST_LIMIT = -1
  DEFINED_QUERIES = {
    'instance-name-id:' => 'instances-for-name-id:',
    'instances-for-name-id' => 'instances-for-name-id:',
    'instances for name id' => 'instances-for-name-id:',
    'names with instances' => 'instances-for-name:',
    'names + instances' => 'instances-for-name:',
    'instance-name:' => 'instances-for-name:',
    'instances-for-name:' => 'instances-for-name:',
    'instance-ref-id:' => 'instances-for-ref-id:',
    'instances-for-ref-id:' => 'instances-for-ref-id:',
    'instances for ref id' => 'instances-for-ref-id:',
    'instance-ref-id-sort-by-page:' => 'instances-for-ref-id-sort-by-page:',
    'instances-for-ref-id-sort-by-page:' => 'instances-for-ref-id-sort-by-page:',
    'instances for ref id sort by page' => 'instances-for-ref-id-sort-by-page:',
    'instances sorted by page for ref id' => 'instances-for-ref-id-sort-by-page:',
    'references with instances' => 'instances-for-references',
    'references + instances' => 'instances-for-references',
    'instance is cited' => 'instance-is-cited',
    'instance is cited by' => 'instance-is-cited-by'
  }

  SIMPLE_QUERY_TARGETS = {
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
    debug("initialize: params: #{params}")
    @params = params
    parse_request
    @count_allowed = true
  end

  def debug(s)
    Rails.logger.debug("Search::ParsedRequest #{s}")
  end

  def inspect
    "Parsed Query: defined_query: #{@defined_query}; where_arguments: #{@where_arguments}, defined_query_args: #{@defined_query_args}"
  end

  def parse_request
    debug("parse_request start: ===============================")
    debug("parse_request start: @params: #{@params}")
    @query_string = @params['query_string'].gsub(/  */,' ')
    debug("parse_request @query_string: #{@query_string}")
    @query_target = (@params['query_target']||'').strip.downcase
    debug("parse_request @query_target: #{@query_target}")
    # Before splitting on spaces, make sure every colon has at least one space after it.
    remaining_tokens = @query_string.strip.gsub(/:/,': ').gsub(/:  /,': ').split(/ /)
    remaining_tokens = parse_query_target(remaining_tokens)
    #unless @defined_query
      remaining_tokens = parse_count_or_list(remaining_tokens)
      remaining_tokens = parse_limit(remaining_tokens)  # limit needs to be a delimited field limit: NNN to avoid confusion with IDs.
      remaining_tokens = parse_target(remaining_tokens)
      #remaining_tokens = parse_defined_query(remaining_tokens)
      remaining_tokens = parse_common_and_cultivar(remaining_tokens)
      remaining_tokens = parse_order(remaining_tokens)
      remaining_tokens = gather_where_arguments(remaining_tokens)
    #end
  end

  def parse_query_target(tokens)
    query_target_downcase = @query_target.downcase
    if DEFINED_QUERIES.has_key?(query_target_downcase)
      debug("parse_query_target - #{query_target_downcase} is recognized as a defined query.")
      @defined_query = DEFINED_QUERIES[query_target_downcase]
      @target_button_text = @params['query_target'].capitalize.gsub(/\bid\b/,'ID').gsub('name','Name').gsub(/ref/,'Ref')
    else
      debug("parse_query_target - '#{query_target_downcase}' is NOT recognized as a defined query.")
      @defined_query = false
    end
    tokens
  end

  def xparse_defined_query(tokens)
    debug("parse_defined_query start: tokens: #{tokens.join(',')}")
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

  # Need to refactor - to avoid limit being confused with an ID.
  # Make limit a field limit: 999
  def parse_limit(tokens)
    debug "parse_limit for tokens: #{tokens.join(' ')}"
    @limited = @list
    joined_tokens = tokens.join(' ')
    if @list
      if joined_tokens.match(/limit: \d{1,}/i)
        @limit = joined_tokens.match(/limit: (\d{1,})/i)[1].to_i
        joined_tokens = joined_tokens.gsub(/limit: *\d{1,}/i,'')
      else
        @limit = DEFAULT_LIST_LIMIT
      end
    else # count
      # remove any limit:
      joined_tokens = joined_tokens.gsub(/limit: *\d{1,}/i,'')
      @limit = 0
    end
    if joined_tokens.match(/limit: *[^\s\\]{1,}/i).present?
      bad_limit = joined_tokens.match(/limit: *([^\s\\]{1,})/i)[1]
      raise "Invalid limit: #{bad_limit}"
    end
    tokens = joined_tokens.split(' ')
    tokens
  end

  def xparse_limit(tokens)
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

  #def parse_target(tokens)
    #if query_target_valid?
      #target = SIMPLE_QUERY_TARGETS[@query_target]
      #if target == 'defined query'
        #@defined_query = DEFINED_QUERIES[@query_target]
        #@defined_query_arg = tokens.join(' ')
        #tokens = []
      #else
        #@defined_query = false
    #tokens
  #end
  #
  def parse_target(tokens)
    debug(' parse_target')
    if @defined_query == false
      debug(" parse_target not a defined query")
      if SIMPLE_QUERY_TARGETS.has_key?(@query_target)
        @target_table = SIMPLE_QUERY_TARGETS[@query_target]
        @target_button_text = @target_table.capitalize.pluralize
        debug(" parse_target has a simple query! @target_table: #{@target_table}")
        if SIMPLE_QUERY_TARGETS.has_key?(tokens.first)
          tokens = tokens.drop(1)
        end
      else
        raise "Cannot parse target: #{@query_target}"
      end
    end
    tokens
  end

  def xparse_target(tokens)
    debug(' parse_target')
    if @defined_query == false
      debug(" parse_target not a defined query")
      if SIMPLE_QUERY_TARGETS.has_key?(@query_target)
        @target_table = SIMPLE_QUERY_TARGETS[@query_target]
        debug(" parse_target has a simple query! @target_table: #{@target_table}")
        if SIMPLE_QUERY_TARGETS.has_key?(tokens.first)
          tokens = tokens.drop(1)
        end
      elsif tokens.blank?
        debug(" parse_target tokens blank")
        @target_table = DEFAULT_TARGET
      elsif SIMPLE_QUERY_TARGETS.has_key?(tokens.first)
        @target_table = SIMPLE_QUERY_TARGETS[tokens.first]
          tokens = tokens.drop(1)
      else
        debug(" parse_target is resorting to the DEFAULT_TARGET")
        @target_table = DEFAULT_TARGET
      end
      @target_button_text = @target_table.capitalize.pluralize
    else
      @target_table = 'for defined query'
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
    debug("gather_where_arguments for tokens: #{tokens}")
    @where_arguments = tokens.join(' ')
    tokens
  end
  
  def canonical_query_string
    @params[:query_string]
  end

end



