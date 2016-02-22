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

# Provide typeahead suggestions based on a search term.
#
# Offer parents of the appropriate rank:
# - infra-species (below species)   : rank must be above the name's rank
#                                     and equal to or below species rank
# - species                         : any rank above species and equal to
#                                     or below genus
# - genus, above genus, below family: rank must be above the name's rank
#                                     and equal to or below family
# - family and above                : any rank above the name's rank
# - [unranked]                      : [unranked] and any non-deprecated
#                                     rank above [unranked]
#
# Exclude names marked as duplicates.
# Show an instance count for each result.
class Name::AsTypeahead::ForParent
  attr_reader :suggestions,
              :params
  SEARCH_LIMIT = 50

  def initialize(params)
    @params = params
    if @params[:term].blank?
      @suggestions = []
    else
      @suggestions = query
    end
  end

  def prepared_search_term
    @params[:term].gsub(/\*/, "%").downcase + "%"
  end

  def core_query
    Name.not_a_duplicate
      .full_name_like(prepared_search_term)
      .avoids_id(@params[:avoid_id].try("to_i") || -1)
      .joins(:name_status)
      .joins("left outer join instance on instance.name_id = name.id")
      .order_by_full_name
      .limit(SEARCH_LIMIT)
  end

  def rank_query
    rank_id = @params[:rank_id]
    if rank_id != "undefined" && NameRank.id_is_unranked?(rank_id.to_i)
      @qry = @qry.ranks_for_unranked
    else
      @qry = @qry.from_a_higher_rank(rank_id)
      @qry = @qry.but_rank_not_too_high(rank_id)
    end
  end

  def instance_phrase(count)
    ActionController::Base.helpers.pluralize(count, "instance")
  end

  def query
    @qry = core_query
    @qry = rank_query
    @qry = @qry.select_fields_for_parent_typeahead
           .group("name.id,name.full_name,name_rank.name,name_status.name")
           .collect do |n|
             { value: "#{n.full_name} | #{n.name_rank_name} | "\
                      "#{n.name_status_name} | "\
                      "#{instance_phrase(n.instance_count)} ",
               id: n.id }
           end
  end
end
