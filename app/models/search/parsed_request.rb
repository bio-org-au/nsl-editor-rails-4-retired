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
              :count_allowed,
              :defined_query,
              :defined_query_arg,
              :id,
              :include_common_and_cultivar_session,
              :limit,
              :limited,
              :list,
              :order,
              :params,
              :query_string,
              :query_target,
              :target_table,
              :target_button_text,
              :user,
              :where_arguments

  DEFAULT_LIST_LIMIT = 100
  SIMPLE_QUERY_TARGETS = {
    "author" => "author",
    "authors" => "author",
    "instance" => "instance",
    "instances" => "instance",
    "name" => "name",
    "names" => "name",
    "reference" => "reference",
    "references" => "reference",
    "ref" => "reference",
    "tree" => "tree",
  }

  def initialize(params)
    debug("initialize: params: #{params}")
    @params = params
    @query_string = @params["query_string"].gsub(/  */, " ")
    @query_target = (@params["query_target"] || "").strip.downcase
    @user = @params[:current_user]
    parse_request
    @count_allowed = true
  end

  def debug(s)
    Rails.logger.debug("Search::ParsedRequest #{s}")
  end

  def inspect
    "Parsed Request: count: #{@count}; list: #{@list};
    defined_query: #{@defined_query}; where_arguments: #{@where_arguments},
    defined_query_args: #{@defined_query_args};
    query_target: #{@query_target};
    common_and_cultivar: #{@common_and_cultivar};
    include_common_and_cultivar_session
    : #{@include_common_and_cultivar_session};"
  end

  def parse_request
    debug("parse_request start: @params: #{@params}")
    unused_qs_tokens = normalise_query_string.split(/ /)
    parsed_defined_query = Search::ParsedDefinedQuery.new(@query_target)
    @defined_query = parsed_defined_query.defined_query
    @target_button_text = parsed_defined_query.target_button_text
    unused_qs_tokens = parse_count_or_list(unused_qs_tokens)
    unused_qs_tokens = parse_limit(unused_qs_tokens)
    unused_qs_tokens = parse_target(unused_qs_tokens)
    unused_qs_tokens = parse_common_and_cultivar(unused_qs_tokens)
    @where_arguments = unused_qs_tokens.join(" ")
  end

  # Before splitting on spaces, make sure every colon has at least 1 space
  # after it.
  def normalise_query_string
    @query_string.strip.gsub(/:/, ": ").gsub(/:  /, ": ")
  end

  def parse_count_or_list(tokens)
    if tokens.blank? then default_list_and_count
    elsif tokens.first.match(/\Acount\z/i)
      tokens = tokens.drop(1)
      counting
    elsif tokens.first.match(/\Alist\z/i)
      tokens = tokens.drop(1)
      listing
    else default_list_and_count
    end
    tokens
  end

  def default_list_and_count
    @list = true
    @count = !@list
  end

  def counting
    @count = true
    @list = !@count
  end

  def listing
    @list = true
    @count = !@list
  end

  # TODO: Refactor - to avoid limit being confused with an ID.
  #       Make limit a field limit: 999
  def parse_limit(tokens)
    debug "parse_limit for tokens: #{tokens.join(' ')}"
    @limited = @list
    joined_tokens = tokens.join(" ")
    if @list
      joined_tokens = apply_list_limit(joined_tokens)
    else # count
      joined_tokens = remove_limit_for_count(joined_tokens)
    end
    filter_bad_limit(joined_tokens).split(" ")
  end

  def apply_list_limit(joined_tokens)
    if joined_tokens.match(/limit: \d{1,}/i)
      @limit = joined_tokens.match(/limit: (\d{1,})/i)[1].to_i
      joined_tokens = joined_tokens.gsub(/limit: *\d{1,}/i, "")
    else
      @limit = DEFAULT_LIST_LIMIT
    end
    joined_tokens
  end

  def remove_limit_for_count(joined_tokens)
    @limit = 0
    joined_tokens.gsub(/limit: *\d{1,}/i, "")
  end

  def filter_bad_limit(joined_tokens)
    if joined_tokens.match(/limit: *[^\s\\]{1,}/i).present?
      bad_limit = joined_tokens.match(/limit: *([^\s\\]{1,})/i)[1]
      fail "Invalid limit: #{bad_limit}"
    end
    joined_tokens
  end

  def parse_target(tokens)
    if @defined_query == false
      if SIMPLE_QUERY_TARGETS.key?(@query_target)
        @target_table = SIMPLE_QUERY_TARGETS[@query_target]
        @target_button_text = @target_table.capitalize.pluralize
        tokens = tokens.drop(1) if SIMPLE_QUERY_TARGETS.key?(tokens.first)
      else
        fail "Cannot parse target: #{@query_target}"
      end
    end
    tokens
  end

  def parse_common_and_cultivar(tokens)
    @common_and_cultivar = false
    @include_common_and_cultivar_session = \
      @params["include_common_and_cultivar_session"] ||
      @params["query_common_and_cultivar"] == "t"
    tokens
  end

  def canonical_query_string
    @params[:query_string]
  end
end
