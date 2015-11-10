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
              :error_message,
              :executed_query,
              :more_allowed,
              :parsed_request

  DEFAULT_PAGE_SIZE = 100
  PAGE_INCREMENT_SIZE = 500
  MAX_PAGE_SIZE = 10000

  def initialize(params)
    debug("Search::Base start for user #{params[:current_user].username}")
    @params = params
    @empty = false
    @error = false
    @error_message = ''
    parse_request
    debug(@parsed_request.inspect)
    if @parsed_request.defined_query
      debug("has a defined query: #{@parsed_request.defined_query}")
      run_defined_query
    else
      debug("has a plain query")
      run_query
    end
  end

  def debug(s)
    Rails.logger.debug("Search::Base #{s}")
  end

  def parse_request
    @query_string = @params[:query_string]
    @parsed_request = Search::ParsedRequest.new(@params)
  end

  def to_history
    {"query_string"=> @query_string, 
     "query_target" => @parsed_request.query_target, 
     "result_size" => @executed_query.count, 
     "time_stamp" => Time.now, 
     "error" => false}
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
    debug("run_query for @parsed_request.target_table: #{@parsed_request.target_table}")
    @count_allowed = true
    case @parsed_request.target_table
    when /any/
      raise "cannot run an 'any' search yet"
    when /author/
      debug("\nSearching authors\n")
      @executed_query = Search::OnAuthor::Base.new(@parsed_request)
    when /instance/
      debug("\nSearching instances\n")
      @executed_query = Search::OnInstance::Base.new(@parsed_request)
    when /reference/
      debug("\nSearching references\n")
      @executed_query = Search::OnReference::Base.new(@parsed_request)
    else
      debug("\n else, Searching on names\n")
      @executed_query = Search::OnName::Base.new(@parsed_request)
    end
  end
 
  def run_defined_query
    @count_allowed = false
    raise "Defined queries need an argument." if @parsed_request.defined_query_arg.blank? && @parsed_request.where_arguments.blank?
    case @parsed_request.defined_query
    when /instances-for-name-id:/
      debug("\nrun_defined_query instances-for-name-id:\n")
      @executed_query = Name::DefinedQuery::NameIdWithInstances.new(@parsed_request)
    when /names-plus-instances:/
      debug("\nrun_defined_query instances-for-name:\n")
      @executed_query = Name::DefinedQuery::NamesPlusInstances.new(@parsed_request)
    when /instances-for-ref-id:/
      debug("\nrun_defined_query instances-for-ref-id:\n")
      @executed_query = Reference::DefinedQuery::ReferenceIdWithInstances.new(@parsed_request)
      #@results = Instance::AsSearchEngine.for_ref_id(@defined_query_arg, @limit,'name')
    when /instances-for-ref-id-sort-by-page:/
      debug("\nrun_defined_query instances-for-ref-id-sort-by-page:\n")
      @executed_query = Reference::DefinedQuery::ReferenceIdWithInstancesSortedByPage.new(@parsed_request)
      #@results = Instance::AsSearchEngine.for_ref_id(@defined_query_arg, @limit,'page')
    when /references-name-full-synonymy/
      debug("\nrun_defined_query references-name-full-synonymy\n")
      @executed_query = Reference::DefinedQuery::ReferencesNamesFullSynonymy.new(@parsed_request)
    when /\Ainstance-is-cited\z/
      debug("\nrun_defined_query instance-id-is-cited\n")
      @executed_query = Instance::DefinedQuery::IsCited.new(@parsed_request)
    when /\Ainstance-is-cited-by\z/
      debug("\nrun_defined_query instance-id-is-cited-by\n")
      @executed_query = Instance::DefinedQuery::IsCitedBy.new(@parsed_request)
    when /\Aaudit\z/
      debug("\nrun_defined_query audit\n")
      @executed_query = Audit::DefinedQuery::Base.new(@parsed_request)
      debug("after run_defined_query audit; @executed_query.limited: #{ @executed_query.limited }")
      debug("after run_defined_query audit; @executed_query.limited: #{ @executed_query.limited }")
      debug("after run_defined_query audit; @executed_query.limited: #{ @executed_query.limited }")
      debug("after run_defined_query audit; @executed_query.limited: #{ @executed_query.limited }")
      debug("after run_defined_query audit; @executed_query.limited: #{ @executed_query.limited }")
      debug("after run_defined_query audit; @executed_query.limited: #{ @executed_query.limited }")
    when /\Areferences-with-novelties\z/
      debug("\nrun_defined_query references-with-novelties\n")
      @executed_query = Reference::DefinedQuery::ReferencesWithNovelties.new(@parsed_request)
    when /\Areferences-accepted-names-for-id\z/i
      debug("\nrun_defined_query references-accepted-names-for-id\n")
      @executed_query = Reference::DefinedQuery::ReferencesAcceptedNamesForId.new(@parsed_request)
    else
      raise "Run Defined Query has no match for #{@parsed_request.defined_query}"
    end
  end

  ########################################################################################
  def search_from_string(params)
    debug("Search::Base -> search_from_string")
    @specific_search = Search::FromString.new(params)
  end

  def search_from_fields(params)
    debug("Search::Base -> search_from_fields")
    case search_target(params['search_target'])
    when /name/
      debug("Search::Base -> Name::Search")
      @specific_search = Name::Search.new(params)
    else
      raise 'not implemented yet'
    end
  end 

  def empty_search(params)
    debug("Search::Base -> empty_search")
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


