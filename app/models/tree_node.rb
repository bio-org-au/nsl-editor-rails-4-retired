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

class TreeNode < ActiveRecord::Base
  self.table_name = "tree_node"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :tree, class_name: TreeArrangement, foreign_key: "tree_arrangement_id"
  belongs_to :name, class_name: Name
  belongs_to :instance, class_name: Instance
  has_many   :sublinks, class_name: ::TreeLink, foreign_key: "supernode_id"

  def delete?
    subnodes.empty?
  end

  def subnodes
    sublinks.map { |sublink| sublink.node unless sublink.node.name_id.nil? }.compact
  end
end
