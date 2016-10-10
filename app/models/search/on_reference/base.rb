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
class Search::OnReference::Base
  attr_reader :results,
              :limited,
              :info_for_display,
              :rejected_pairings,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :id,
              :count,
              :show_csv,
              :total

  def initialize(parsed_request)
    @parsed_request = parsed_request
    run_query
  end

  def run_query
    @has_relation = true
    @rejected_pairings = []
    if @parsed_request.count
      run_count_query
    else
      run_list_query
    end
  end

  def run_count_query
    count_query = Search::OnReference::CountQuery.new(@parsed_request)
    @relation = count_query.sql
    @total = @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @show_csv = false
    @total = nil
  end

  def run_list_query
    list_query = Search::OnReference::ListQuery.new(@parsed_request)
    @relation = list_query.sql
    @references = relation.all
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    consider_instances
    @count = @results.size
    @show_csv = false
    calculate_total
  end

  def consider_instances
    if @parsed_request.show_instances
      show_instances
    else
      @results = @references
    end
  end

  def show_instances
    @results = []
    @references.each do |ref|
      @results << ref
      instances_query = Instance::AsArray::ForReference.new(ref)
      instances_query.results.each { |i| @results << i }
    end
  end

  def debug(s)
    Rails.logger.debug("Search::OnReference::Base: #{s}")
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = if @parsed_request.show_instances
               @results.size
             else
               @relation.except(:offset, :limit, :order).count
             end
  end
end
