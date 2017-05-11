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
#   A list of names.
class Name::AsTypeahead::ForWorkspaceParentName
  attr_reader :suggestions,
              :params
  SEARCH_LIMIT = 50

  def initialize(params, workspace)
    @params = params
    @workspace = workspace
    @suggestions = if @params[:term].blank?
                     []
                   else
                     query
                   end
  end

  def prepared_search_term
    @params[:term].tr("*", "%").downcase + "%"
  end

  def basic_query
    Name.not_a_duplicate
        .where(["lower(full_name) like lower(?)", prepared_search_term])
        .includes(:name_status)
        .includes(:name_rank)
        .joins(:tree_nodes)
        .where(["tree_node.tree_arrangement_id in (?,?)", @workspace.id, @workspace.base_arrangement_id])
        .where("exists (select null from instance where instance.name_id = name.id)")
        .order("name_rank.sort_order, lower(full_name)")
        .limit(SEARCH_LIMIT)
  end

  def query
    if @params[:allow_higher_ranks].to_i > 0
      higher_ranks_query
    else
      normal_query
    end
  end

  def normal_query
    basic_query
      .includes(:name_rank)
      .joins(:name_rank)
      .where("name_rank.sort_order >= (select max(sort_order) from name_rank where major and name != 'Tribus' and sort_order < (select sort_order from name_rank where id = (select name_rank_id from name where id = ?)))",params[:name_id])
      .where("name_rank.sort_order < (select sort_order from name_rank where id = (select name_rank_id from name where id = ?))",params[:name_id])
      .collect do |n|
      { value: "#{n.full_name} - #{n.name_rank.name}", id: n.id }
    end
  end

  def higher_ranks_query
    basic_query
      .includes(:name_rank)
      .joins(:name_rank)
      .where("name_rank.sort_order < (select sort_order from name_rank where id = (select name_rank_id from name where id = ?))",params[:name_id])
      .collect do |n|
      { value: "#{n.full_name} - #{n.name_rank.name}", id: n.id }
    end
  end
end
