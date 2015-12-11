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
              :include_common_and_cultivar_session, 
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
              :count_allowed,
              :user

  DEFAULT_LIST_LIMIT = 100
  DEFINED_QUERIES = {
    'instance-name-id:' => 'instances-for-name-id:',
    'instances-for-name-id' => 'instances-for-name-id:',
    'instances for name id' => 'instances-for-name-id:',
    'names with instances' => 'names-plus-instances:',
    'names + instances' => 'names-plus-instances:',
    'names plus instances' => 'names-plus-instances:',
    'instance-name:' => 'names-plus-instances:',
    'instances-for-name:' => 'names-plus-instances:',
    'instance-ref-id:' => 'instances-for-ref-id:',
    'instances-for-ref-id:' => 'instances-for-ref-id:',
    'instances for ref id' => 'instances-for-ref-id:',
    'instance-ref-id-sort-by-page:' => 'instances-for-ref-id-sort-by-page:',
    'instances-for-ref-id-sort-by-page:' => 'instances-for-ref-id-sort-by-page:',
    'instances for ref id sort by page' => 'instances-for-ref-id-sort-by-page:',
    'instances sorted by page for ref id' => 'instances-for-ref-id-sort-by-page:',
    'references with instances' => 'references-name-full-synonymy',
    'references, names, full synonymy' => 'references-name-full-synonymy',
    'references + instances' => 'references-name-full-synonymy',
    'references with novelties' => 'references-with-novelties',
    'references, accepted names for id' => 'references-accepted-names-for-id',
    'references shared names' => 'references-shared-names',
    'instance is cited' => 'instance-is-cited',
    'instance is cited by' => 'instance-is-cited-by',
    'audit' => 'audit',
    'review' => 'audit',
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
    "Parsed Request: count: #{@count}; list: #{@list}; defined_query: #{@defined_query};" +
    "where_arguments: #{@where_arguments}, defined_query_args: #{@defined_query_args}; " +
    "query_target: #{@query_target}; " +
    "common_and_cultivar: #{@common_and_cultivar}; include_common_and_cultivar_session: #{@include_common_and_cultivar_session};"
  end

  def as_a_list_request
    @count = false
    @list = true
    self
  end

  def parse_request
    debug("parse_request start: ===============================")
    debug("parse_request start: @params: #{@params}")
    @query_string = @params['query_string'].gsub(/  */,' ')
    debug("parse_request @query_string: #{@query_string}")
    @query_target = (@params['query_target']||'').strip.downcase
    debug("parse_request @query_target: #{@query_target}")
    @user = @params[:current_user]
    # Before splitting on spaces, make sure every colon has at least one space after it.
    remaining_tokens = @query_string.strip.gsub(/:/,': ').gsub(/:  /,': ').split(/ /)
    remaining_tokens = parse_query_target(remaining_tokens)
    remaining_tokens = parse_count_or_list(remaining_tokens)
    remaining_tokens = parse_limit(remaining_tokens)  # limit needs to be a delimited field limit: NNN to avoid confusion with IDs.
    remaining_tokens = parse_target(remaining_tokens)
    remaining_tokens = parse_common_and_cultivar(remaining_tokens)
    remaining_tokens = parse_order(remaining_tokens)
    remaining_tokens = gather_where_arguments(remaining_tokens)
  end

  def parse_query_target(tokens)
    query_target_downcase = @query_target.downcase
    if DEFINED_QUERIES.has_key?(query_target_downcase)
      debug("parse_query_target - #{query_target_downcase} is recognized as a defined query.")
      @defined_query = DEFINED_QUERIES[query_target_downcase]
      @target_button_text = @params['query_target'].capitalize 
    else
      debug("parse_query_target - '#{query_target_downcase}' is NOT recognized as a defined query.")
      @defined_query = false
    end
    tokens
  end

  def parse_count_or_list(tokens)
    if tokens.blank?
      @list = true
      @count = !@list
    elsif tokens.first.match(/\Acount\z/i)
      tokens = tokens.drop(1)
      @count = true
      @list = !@count
    elsif tokens.first.match(/\Alist\z/i)
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

  def parse_common_and_cultivar(tokens)
    @common_and_cultivar = false
    @include_common_and_cultivar_session = @params['include_common_and_cultivar_session']
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



