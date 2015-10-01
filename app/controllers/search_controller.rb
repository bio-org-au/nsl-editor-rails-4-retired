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
class SearchController < ApplicationController

  def xindex
    logger.debug("SearchController#index.")
    logger.debug(params.class)
    @no_search_result_details = true
    if params[:count] 
      render text: 'count'
      #run_count
    elsif params[:advanced] 
      redirect_to advanced_search_string_url(query: params[:query])
    else # assume anything else is a search
      @search_results = []
      search
    end
  end

  def index
    if params[:query].blank?
      @search = Search::Empty.new(params) 
    else
      params[:query_string] = "#{params[:query_on]} #{params[:query]}"
      @search = Search::Base.new(params)
    end
  end

  def search
    logger.debug("SearchController#search.")
    @debug = false
    if params[:query].blank? && params[:query_on].blank?
      params[:query] = ''
      params[:query_on] = 'Name'
      params[:query_common_and_cultivar] = 'f'
      params[:query_field] = ''
    elsif params[:query_on] == 'tree'
      params[:query_field] = 'apc' if params[:query_field].blank?
      params[:query] = Name.find_by(full_name: 'Plantae Haeckel').id if params[:query].blank?
      @ng_template_path = tree_ng_path('dummy').gsub(/dummy/,'')
      logger.debug("@ng_template_path: #{@ng_template_path}")
      render 'trees/index'
    else
      params[:query_on] ||= 'Name'
      params[:query_common_and_cultivar] ||= 'f'
      # Name searches on ID should include common and cultivar
      params[:query_common_and_cultivar] = 't' if params[:query_on].match(/\Aname\z/i) && params[:query].match(/id:/i)
      params[:query_common_and_cultivar] = 't' if params[:query_on].match(/\Aname\z/i) && params[:query].match(/nt:/i)
      params[:query_common_and_cultivar] = 't' if params[:query_on].match(/\Aname\z/i) && (params[:query_field]||'').match(/\Ant\z/i)
      @search = Search.new(params[:query],params[:query_on],params[:query_limit],params[:query_common_and_cultivar]||'f',params[:query_sort],params[:query_field])
      add_query_to_session
      @no_search_result_details = @search.results.size == 0
    end
    @autofocus_search = true
  end

  private

  def add_query_to_session(max = 10)
    session[:queries] ||= []
    session[:queries].delete_if {|q| q == params[:query]}
    session[:queries].push(params[:query])
    session[:queries].shift if session[:queries].size > max
  end

end
