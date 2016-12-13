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

# Represents the tree_node table which is part of the tree/workspace
# database component.
class TreeNode < ActiveRecord::Base
  self.table_name = "tree_node"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :tree, class_name: TreeArrangement, foreign_key: "tree_arrangement_id"
  belongs_to :workspace, class_name: "Tree::Workspace", foreign_key: "tree_arrangement_id"
  belongs_to :name, class_name: Name
  belongs_to :instance, class_name: Instance
  has_many   :sublinks, class_name: ::TreeLink, foreign_key: "supernode_id"
  has_many   :super_links, class_name: ::TreeLink, foreign_key: "subnode_id"
  has_many   :value_links,
            (lambda do
              where("type_uri_id_part in ('distribution','comment')")
             end),
             class_name: ::TreeLink,
             foreign_key: "supernode_id"

  def delete?
    subnodes.empty?
  end

  def subnodes
    sublinks.map { |sublink| sublink.node unless sublink.node.name_id.nil? }.compact
  end

  def valueLink(tree_value_uri)
    if tree_value_uri.is_multi_valued
      TreeLink.where(' supernode_id = ? and type_uri_ns_part_id = ? and type_uri_id_part = ?',
                     self.id,
                     tree_value_uri.link_uri_ns_part.id,
                     tree_value_uri.link_uri_id_part)
    else 
      # This node is supernode for a treelink,  
      # and that treelink must have a "namespace" id (type_uri_ns_part_id)
      # matching the param tree_value_uri.link_uri_ns_part.id
      # and it must have a type_uri_id_part matching the tree_value_uri.link_uri_id_part.
      #
      # Tree_link.type_uri_ns_part_id references tree_uri_ns.id.
      # Tree_link.type_uri_id_part is a string.
      #   
      TreeLink.where(' supernode_id = ? and type_uri_ns_part_id = ? and type_uri_id_part = ?',
                     self.id,
                     tree_value_uri.link_uri_ns_part.id,
                     tree_value_uri.link_uri_id_part).first()
    end


#    Link.where(' supernode = ? and type_uri_ns_part = ? and type_uri_id = ?', self.id, tree_value_uri.link_uri_ns_part, tree_value_uri.link_uri_id_part)
  end
end
