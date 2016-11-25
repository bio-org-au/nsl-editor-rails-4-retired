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

#  A workspace is an unpublished tree (formally a tree arrangement) that can be edited.
class Tree::Public < ActiveRecord::Base
  self.table_name = "tree_arrangement"
  self.primary_key = "id"
  default_scope { where(tree_type: "P").order(:label) }
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  has_many :workspaces, class_name: "Tree::Workspace", foreign_key: "base_arrangement_id"

  def find_placement_of_name(name)
    link_id = TreeArrangement::sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def user_can_edit?(user)
    false
  end

  def self.sp_find_name_in_tree(name_id, tree_id)
    # doing this as bind variables isn't working for me, and anyway
    # it doesn't matter because this select doen't involve a lot of planning
    connection.select_value("select find_name_in_tree(#{name_id}, #{tree_id})")
  end

  def workspaces?
    workspaces.size > 0
  end
end
