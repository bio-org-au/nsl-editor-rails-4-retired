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
              :info_for_display, 
              :limit, 
              :limited, 
              :order, 
              :params, 
              :query_string, 
              :rejected_pairings, 
              :results, 
              :target_table, 
              :where_arguments 

  def initialize(params)
    Rails.logger.debug("Search::Base start")
    @params = params
    @empty = false
    parse_query
    if @defined_query
      defined_query(@parsed_query)
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


