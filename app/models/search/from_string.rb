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
class Search::FromString

  attr_reader :params, :query_string

  def initialize(params)
    Rails.logger.debug("NewSearchFromString start")
    Rails.logger.debug("#{'=' * 40}")
    @params = params
    @query_string = params[:query_string]
    params.each do |key,value|
      Rails.logger.debug("#{key}: #{value}")
    end
    Rails.logger.debug("#{'=' * 40}")
  end

  def specific_search
    @specific_search
  end

  def canonical_search_string
    canon = new Search::CanonicalSearchString(@params)
    canon.search_string
  end

  # give me a canonical search string
  # build the sql
  # - count me or list me?
  # - am i a named search?
  # - has the user said name or reference or author or instance or tree?
  #   - go to that record type search
  # - has the user specified a field or fields?
  # execute the sql
  def results
    results = Name.includes(:name_status) \
            .includes(:name_tags) \
            .lower_full_name_like(@params[:query_string].downcase) \
            .order('full_name')
        results = results.not_common_or_cultivar #if exclude_common_and_cultivar
        #results = results.limit(search_limit) if apply_limit
        results = results.limit(10) 
        results = results.all
  end

end



