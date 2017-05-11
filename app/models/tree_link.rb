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

#   A tree link identifies a placement in a tree.
class TreeLink < ActiveRecord::Base
  self.table_name = "tree_link"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :supernode, class_name: TreeNode, foreign_key: "supernode_id"
  belongs_to :node, class_name: TreeNode, foreign_key: "subnode_id"
  belongs_to :subnode, class_name: TreeNode
  belongs_to :namespace,
             class_name: "TreeUriNs",
             foreign_key: "type_uri_ns_part_id"
  has_many   :workspace_values, -> { order "sort_order" },
             foreign_key: "name_node_link_id"
  has_one    :comment_value, -> { where " field_name = 'comment' " },
             class_name: "WorkspaceValue",
             foreign_key: "name_node_link_id"
  has_one    :distribution_value, -> { where " field_name = 'distribution' " },
             class_name: "WorkspaceValue",
             foreign_key: "name_node_link_id"

  ACCEPTED_RAW = "ApcConcept"
  EXCLUDED_RAW = "ApcExcluded"
  UNTREATED_RAW = "DeclaredBt"

  ACCEPTED = "accepted"
  EXCLUDED = "excluded"
  UNTREATED = "untreated"

  def placed?
    true
  end

  def placed_via_instance?(instance)
    placed? && node.instance.id == instance.id
  end

  def placed_as
    case node.type_uri_id_part
    when ACCEPTED_RAW then
      ACCEPTED
    when EXCLUDED_RAW then
      EXCLUDED
    when UNTREATED_RAW then
      UNTREATED
      # "non-#{@current_workspace.label } parent"
    else
      node.node_type_uri_id_part
    end
  end

  def empty?
    false
  end

  def accepted?
    placed_as == ACCEPTED
  end

  def excluded?
    placed_as == EXCLUDED
  end

  def untreated?
    placed_as == UNTREATED
  end

  def default_to_accepted?
    accepted?
  end

  def default_to_excluded?
    excluded?
  end

  def default_to_untreated?
    untreated?
  end

  def distribution_value?
    workspace_values.collect(&:field_name).include?("distribution")
  end

  def comment_value?
    workspace_values.collect(&:field_name).include?("comment")
  end
end
