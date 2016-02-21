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
  before_filter :hide_details

  def search
    handle_old
    run_tree_search || run_local_search || run_empty_search
    respond_to do |format|
      format.html
      format.csv
    end
  rescue => e
    params[:error_message] = e.to_s
    @search = Search::Error.new(params) unless @search.present?
    save_search
  end

  def tree
    set_tree_defaults
    @search = Search::Tree.new(params)
    @ng_template_path = tree_ng_path("dummy").gsub(/dummy/, "")
    logger.debug("@ng_template_path: #{@ng_template_path}")
    render "trees/index"
  rescue => e
    logger.error("SearchController::tree exception: #{e}")
    params[:error_message] = e.to_s
    @search = Search::Error.new(params)
  end

  def search_name_with_instances
    @search = Search::Base.new(
      "query_string" => "instances-for-name-id: #{params[:name_id]}"
    )
    render "search"
  end

  def set_include_common_and_cultivar
    logger.debug("set_include_common_and_cultivar")
    session[:include_common_and_cultivar] = \
      !session[:include_common_and_cultivar]
  end

  def extras
    mapper = Search::Mapper::Extras.new(params)
    render partial: mapper.partial
  end

  private

  def save_search
    session[:searches] ||= []
    session[:searches].push(@search.to_history)
    trim_session_searches
  rescue => e
    logger.error("Error saving search: #{e}")
    session[:searches] = []
  end

  def trim_session_searches
    session[:searches].shift if session[:searches].size > 2
  end

  def tree_search
    set_tree_defaults
    @search = Search::Tree.new(params)
    @ng_template_path = tree_ng_path("dummy").gsub(/dummy/, "")
    render "trees/index"
  rescue => e
    logger.error("SearchController::tree exception: #{e}")
    params[:error_message] = e.to_s
    @search = Search::TreeError.new(params)
  end

  def handle_old
    handle_old_style_params
    handle_old_targets
  end

  # translate services/search/link
  def handle_old_style_params
    return unless params[:query].present?
    unless params[:query_field] == "name-instances"
      fail "Cannot handle this query-field: #{params[:query_field]}"
    end
    params[:query_target] = "name"
    params[:query_string] = params[:query].sub(/\z/, " show-instances:")
  end

  def handle_old_targets
    return unless params[:query_target].present?
    return unless params[:query_target].match(/Names plus instances/i)
    params[:query_target] = "name"
    return if params[:query_string].match(/show-instances:/)
    params[:query_string] = params[:query_string].sub(/\z/, " show-instances:")
  end

  def run_tree_search
    logger.debug("run_tree_search")
    return false unless params[:query_target].present?
    return false unless params[:query_target].match(/\Atrees*/i)
    params[:query] = params[:query_string]
    tree_search
    true
  end

  def run_local_search
    return false unless params[:query_string].present?
    params[:current_user] = current_user
    params[:include_common_and_cultivar_session] = \
      session[:include_common_and_cultivar]
    @search = Search::Base.new(params)
    save_search
    true
  end

  def run_empty_search
    @search = Search::Empty.new(params)
  end

  def set_tree_defaults
    params[:query_field] = "apc" if params[:query_field].blank?
    params[:query] = plantae_haeckel if params[:query].blank?
  end

  def plantae_haeckel
    Name.find_by(full_name: "Plantae Haeckel").id
  end
end
