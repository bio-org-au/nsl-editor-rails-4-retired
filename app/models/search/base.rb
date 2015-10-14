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
class Search::Base

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
              :rejected_pairings, 
              :results, 
              :target_table, 
              :where_arguments,
              :defined_query,
              :more_allowed

  def initialize(params)
    Rails.logger.debug("Search::Base start")
    @params = params
    @empty = false
    @error = false
    parse_query
    if @defined_query
      Rails.logger.debug("Search::Base has a defined query: #{@defined_query}")
      run_defined_query
    else
      run_query
    end
  end

  def parse_query
    @query_string = @params[:query_string]
    @parsed_query = Search::ParsedQuery.new(@params)
    @count = @parsed_query.count
    @list = @parsed_query.list
    @limit = @parsed_query.limit
    @defined_query = @parsed_query.defined_query
    @defined_query_arg = @parsed_query.defined_query_arg
    @target_table = @parsed_query.target_table
    @common_and_cultivar = @parsed_query.common_and_cultivar
    @order = @parsed_query.order
    @where_arguments = @parsed_query.where_arguments
    @canonical_query_string = @parsed_query.canonical_query_string
  end

  def query_string_for_more
    query_string_without_limit.sub(/^ *list/i,'').sub(/^ *\d+/,'').sub(/^/,'all ')
    raw_limit = @query_string.sub(/^ *list/i,'').trim().split.first

    current_limit = case raw_limit
    when /all/i
      'all'
    when /\d+/
      raw_limit.to_i
    else
      100
    end
    if current_limit == 'all'
      @more_allowed = false
      new_limit = current_limit
    elsif current_limit >= 1000
      @more_allowed = false
      new_limit = current_limit
    else
      @more_allowed = true
      new_limit = current_limit + 500 > 1000 ? 1000 : current_limit + 500
    end
    "#{new_limit} #{query_string_without_limit}"
  end
  
  def run_query
    case @target_table
    when /any/
      raise "cannot run a 'any' search yet"
    when /author/
      Rails.logger.debug("\nSearching authors\n")
      run = Search::OnAuthor::Base.new(@parsed_query)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    when /instance/
      Rails.logger.debug("\nSearching instances\n")
      run = Search::OnInstance::Base.new(@parsed_query)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    when /reference/
      Rails.logger.debug("\nSearching references\n")
      run = Search::OnReference::Base.new(@parsed_query)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    else
      Rails.logger.debug("\nSearching on names\n")
      run = Search::OnName::Base.new(@parsed_query)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    end
  end
 
  def run_defined_query
    case @defined_query
    when /instances-for-name-id:/
      Rails.logger.debug("\nrun_defined_query instances-for-name-id:\n")
      @results = Instance::AsSearchEngine.name_usages(@defined_query_arg)
      @limited = false 
      @common_and_cultivar_included = true 
      @target_table = 'instance'
    when /instances-for-name:/
      Rails.logger.debug("\nrun_defined_query instances-for-name:\n")
      @results = Instance.name_instances(@defined_query_arg, @limit)
      @limited = @results.size == @limit
      @common_and_cultivar_included = true 
      @target_table = 'instance'
    when /instances-for-ref-id:/
      Rails.logger.debug("\nrun_defined_query instances-for-ref-id:\n")
      @results = Instance::AsSearchEngine.for_ref_id(@defined_query_arg, @limit,'name')
      @limited = @results.size == @limit
      @common_and_cultivar_included = true 
      @target_table = 'instance'
    when /instances-for-ref-id-sort-by-page:/
      Rails.logger.debug("\nrun_defined_query instances-for-ref-id-sort-by-page:\n")
      @results = Instance::AsSearchEngine.for_ref_id(@defined_query_arg, @limit,'page')
      @limited = @results.size == @limit
      @common_and_cultivar_included = true 
      @target_table = 'instance'
    else
      raise "Run Defined Query has no match for #{@defined_query}"
    end
  end

  ########################################################################################
  def search_from_string(params)
    Rails.logger.debug("Search::Base -> search_from_string")
    @specific_search = Search::FromString.new(params)
  end

  def search_from_fields(params)
    Rails.logger.debug("Search::Base -> search_from_fields")
    case search_target(params['search_target'])
    when /name/
      Rails.logger.debug("Search::Base -> Name::Search")
      @specific_search = Name::Search.new(params)
    else
      raise 'not implemented yet'
    end
  end 

  def empty_search(params)
    Rails.logger.debug("Search::Base -> empty_search")
    @specific_search = Search::Empty.new(params)
  end

  def search_target(params_search_target = '')
    case params_search_target
    when /any/
      'any'
    when /author/
      'author'
    when /instance/
      'instance'
    when /name/
      'names'
    when /reference/
      'reference'
    else
      'name'
    end
  end

  def specific_search
    @specific_search
  end

end


