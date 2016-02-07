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

# Core search class for Name search
#
# You can run this in the console, once you have a parsed request:
#
# search = Search::OnName::Base.new(parsed_request)
#
class Search::OnName::Base
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
              :results_array

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def run_query(parsed_request)
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
    end
  end

  def run_count_query(parsed_request)
    debug('#run_count_query')
    count_query = Search::OnName::CountQuery.new(parsed_request)
    @has_relation = true
    @relation = count_query.sql
    @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @rejected_pairings = []
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @show_csv = false
  end

  def run_list_query(parsed_request)
    debug('#run_list_query')
    list_query = Search::OnName::ListQuery.new(parsed_request)
    @has_relation = true
    @relation = list_query.sql
    @results = relation.all
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @rejected_pairings = []
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    @show_csv = false
    show_instances(parsed_request)
    @count = @results_array.size
  end

  def show_instances(parsed_request)
    debug('show_instances')
    if parsed_request.show_instances
      @results_array = []
      i = Instance.first
      i.display_as = 'Instance'
      @results.each do |name|
        Instance::AsSearchEngine.name_usages(name.id).each do |usage_rec|
          @results_array << usage_rec
        end
      end
    else
      @results_array = @results.to_a
    end
  end

  def debug(s)
    Rails.logger.debug("Search::OnName::Base: #{s}")
  end

  def csv?
    @show_csv
  end
end
