# frozen_string_literal: true
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
      format.csv do
        data = @search.executed_query.results.to_csv
        begin
          data = data.unicode_normalize(:nfc).encode('UTF-16LE')
          data = "\xFF\xFE".dup.force_encoding('UTF-16LE') + data
        rescue => encoding_error
          logger.error(encoding_error.to_s)
          logger.error("This CSV error in the SearchController does not")
          logger.error("prevent CSV data being created but it does indicate")
          logger.error("failure to encode the CSV as UTF-16LE")
        end
        send_data data
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    params[:error_message] = "That query did not work. Please check the \
    search directives and arguments."
    logger.error("Search error: #{e.to_s}")
    @search = Search::Error.new(params) unless @search.present?
  rescue => e
    params[:error_message] = e.to_s
    @search = Search::Error.new(params) unless @search.present?
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

  def set_include_common_and_cultivar
    session[:include_common_and_cultivar] = \
      !session[:include_common_and_cultivar]
  end

  def extras
    mapper = Search::Mapper::Extras.new(params)
    render partial: mapper.partial
  end

  def reports
  end

  private

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
    handle_old_ffox
  end

  # translate services/search/link
  def handle_old_style_params
    return unless params[:query].present?
    unless params[:query_field] == "name-instances"
      raise "Cannot handle this query-field: #{params[:query_field]}"
    end
    params[:query_target] = "name"
    params[:query_string] = params[:query].sub(/\z/, " show-instances:")
  end

  def handle_old_targets
    return unless params[:query_target].present?
    return unless params[:query_target] =~ /Names plus instances/i
    params[:query_target] = "name"
    return if params[:query_string] =~ /show-instances:/
    params[:query_string] = params[:query_string].sub(/\z/, " show-instances:")
  end

  def handle_old_ffox
    session[:old_ffox] = params[:old_ffox].present? &&
                         params[:old_ffox].match(/true/i)
  end

  def run_tree_search
    logger.debug("run_tree_search")
    return false unless params[:query_target].present?
    return false unless params[:query_target] =~ /\Atrees*/i
    params[:query] = params[:query_string]
    tree_search
    true
  end

  def run_local_search
    return false unless params[:query_string].present?
    @focus_id = params[:focus_id]
    params[:current_user] = current_user
    params[:include_common_and_cultivar_session] = \
      session[:include_common_and_cultivar]
    @search = Search::Base.new(params)
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
