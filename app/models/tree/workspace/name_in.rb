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

#  A name can be placed in a workspace
#  Using "NameIn" to avoid Ruby using the Name class.
class Tree::Workspace::NameIn < ActiveRecord::Base
  self.table_name = "name"
  self.primary_key = "id"
  attr_accessor :workspace_id, :link_id

  def placed?
    link_id > 0
  end

  def placed_as
    "SOME - THING"
  end

  # Once set, you cannot change the workspace.
  def workspace_id=(id)
    throw "Cannot change workspace_id" unless @workspace_id.nil?
    @workspace_id = id
  end

  # Once set, you cannot change the link_id.
  def link_id=(id)
    throw "Cannot change link_id" unless @link_id.nil?
    @link_id = id.to_i
  end

  # Association with lambda?
  def workspace
    TreeArrangement.find(@workspace_id)
  end

  def self.find_in_workspace(id, workspace_id)
    name = Tree::Workspace::Name.find(id)
    name.workspace_id = workspace_id.to_i
    name.link_id = ActiveRecord::Base.connection.select_value("select find_name_in_tree(#{name.id}, #{workspace_id})")
    name
  end
end
