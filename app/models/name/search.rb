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
class Name::Search
  attr_reader :preview_only,
              :params,
              :list_or_count,
              :search_target,
              :name_search_name,
              :name_search_name_type_id,
              :name_search_author_abbrev,
              :name_search_ex_author_abbrev,
              :name_search_base_author_abbrev,
              :name_search_ex_base_author_abbrev,
              :name_search_sanctioning_author_abbrev,
              :name_search_comments,
              :name_search_comments_by,
              :parsed_params

  def initialize(params)
    Rails.logger.debug("Name::Search start")
    @preview_only = params["preview"] == "Preview"
    @do_search = !@preview_only
    @search_target = "names"
    @params = params
    set_param_attributes
    parse_params
  end

  def set_param_attributes
    Rails.logger.debug("set_param_attributes")
    Rails.logger.debug(@params)
    @list_or_count = @params["list_or_count"]
    @name_search_name = @params["name_search_name"]
    @name_search_name_type_id = @params["name_search_name_type_id"]
    @name_search_author_abbrev = @params["name_search_author_abbrev"]
    @name_search_ex_author_abbrev = @params["name_search_ex_author_abbrev"]
    @name_search_base_author_abbrev = @params["name_search_base_author_abbrev"]
    @name_search_ex_base_author_abbrev = @params["name_search_ex_base_author_abbrev"]
    @name_search_sanctioning_author_abbrev = @params["name_search_sanctioning_author_abbrev"]
    @name_search_comments = @params["name_search_comments"]
    @name_search_comments_by = @params["name_search_comments_by"]
  end

  def parse_params
    @parsed_params = search_target
    @parsed_params << %( name: "#{@name_search_name}%") if @name_search_name.present?
    @parsed_params << %( author-abbrev: "#{@name_search_author_abbrev}") if @name_search_author_abbrev.present?
    @parsed_params << %( ex-author-abbrev: "#{@name_search_ex_author_abbrev}") if @name_search_ex_author_abbrev.present?
    @parsed_params << %( base-author-abbrev: "#{@name_search_base_author_abbrev}") if @name_search_base_author_abbrev.present?
    @parsed_params << %( ex-base-author-abbrev: "#{@name_search_ex_base_author_abbrev}") if @name_search_ex_base_author_abbrev.present?
    @parsed_params << %( sanctioning-author-abbrev: "#{@name_search_sanctioning_author_abbrev}") if @name_search_sanctioning_author_abbrev.present?
    @parsed_params << %( comments: "#{@name_search_comments}") if @name_search_comments.present?
    @parsed_params << %( comments-by: "#{@name_search_comments_by}") if @name_search_comments_by.present?
  end

  def results
    []
  end

  def to_s
    "[new] Search; params: #{@params}; @parsed_params: #{@parsed_params} "
  end
end
