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

  attr_reader :empty, 
              :error, 
              :parsed_request,
              :common_and_cultivar_included,
              :limited, 
              :results, 
              :more_allowed,
              :error_message,
              :sql

  DEFAULT_PAGE_SIZE = 100
  PAGE_INCREMENT_SIZE = 500
  MAX_PAGE_SIZE = 10000

  def initialize(params)
    Rails.logger.debug("Search::Base start")
    @params = params
    @empty = false
    @error = false
    @error_message = ''
    parse_request
    if @defined_query
      Rails.logger.debug("Search::Base has a defined query: #{@defined_query}")
      run_defined_query
    else
      run_query
    end
  end

  def parse_request
    @query_string = @params[:query_string]
    @parsed_request = Search::ParsedRequest.new(@params)
  end

  def to_history
    {"query_string"=> @query_string, "query_target" => @parsed_request.target_table, "result_size" => @count ? @results : @results.size, "time_stamp" => Time.now, "error" => false}
  end

  def page_increment_size
    PAGE_INCREMENT_SIZE
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
    elsif current_limit >= MAX_PAGE_SIZE
      @more_allowed = false
      new_limit = current_limit
    else
      @more_allowed = true
      new_limit = (current_limit + PAGE_INCREMENT_SIZE > MAX_PAGE_SIZE) ? MAX_PAGE_SIZE : current_limit + PAGE_INCREMENT_SIZE
    end
    "#{new_limit} #{query_string_without_limit}"
  end
  
  def run_query
    @count_allowed = true
    @sql = ''
    case @target_table
    when /any/
      raise "cannot run an 'any' search yet"
    when /author/
      Rails.logger.debug("\nSearching authors\n")
      run = Search::OnAuthor::Base.new(@parsed_request)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    when /instance/
      Rails.logger.debug("\nSearching instances\n")
      run = Search::OnInstance::Base.new(@parsed_request)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    when /reference/
      Rails.logger.debug("\nSearching references\n")
      run = Search::OnReference::Base.new(@parsed_request)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    else
      Rails.logger.debug("\nSearching on names\n")
      run = Search::OnName::Base.new(@parsed_request)
      @results = run.results
      @limited = run.limited
      @info_for_display = run.info_for_display
      @rejected_pairings = run.rejected_pairings
      @common_and_cultivar_included = run.common_and_cultivar_included
    end
    @sql = run.relation.to_sql
  end
 
  def run_defined_query
    @sql = ''
    @count_allowed = false
    case @defined_query
    when /instances-for-name-id:/
      Rails.logger.debug("\nrun_defined_query instances-for-name-id:\n")
      @results = Instance::AsSearchEngine.name_usages(@defined_query_arg)
      @limited = false 
      @common_and_cultivar_included = true 
      @target_table = 'instance'
    when /instances-for-name:/
      Rails.logger.debug("\nrun_defined_query instances-for-name:\n")
      #@results = Instance.name_instances(@defined_query_arg, @limit)
      #@limited = @results.size == @limit
      #@common_and_cultivar_included = true 
      #@target_table = 'instance'
      defined_query = Instance::DefinedQuery::NamesWithInstances.new(@parsed_request)
      @results = defined_query.results
      @limited = defined_query.limited
      @common_and_cultivar_included = defined_query.limited
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


