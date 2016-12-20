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

#  A tree - usually a classification or a classification workspace
class TreeArrangement < ActiveRecord::Base
  self.table_name = "tree_arrangement"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  scope :public_ones, -> { where(tree_type: "P").order(:label) }

  belongs_to :base_arrangement, class_name: TreeArrangement
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  has_many :tree_value_uris,
           (lambda do
              order("sort_order")
            end),
           foreign_key: "root_id"
  has_many :editable_tree_value_uris,
           (lambda do
              where("not is_multi_valued and not is_resource ")
                .order("sort_order")
            end),
           class_name: "TreeValueUri",
           foreign_key: "root_id"
  has_many :workspaces,
           class_name: "Tree::Workspace",
           foreign_key: "base_arrangement_id"

  def self.menu_query
    TreeArrangement.public_ones
                   .joins(:workspaces)
                   .select("tree_arrangement.id, tree_arrangement.label,
    workspaces_tree_arrangement.id as workspace_id,
    workspaces_tree_arrangement.title as workspace_title")
                   .order("tree_arrangement.label,
    workspaces_tree_arrangement.title")
  end

  def workspaces?
    !workspaces.empty?
  end

  def find_placement_of_name(name)
    link_id = TreeArrangement.sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def self.sp_find_name_in_tree(name_id, tree_id)
    # doing this as bind variables isn't working for me, and anyway
    # it doesn't matter because this select doen't involve a lot of planning
    connection.select_value("select find_name_in_tree(#{name_id}, #{tree_id})")
  end

  def self.update_value_url(username, tree_id, name, value_uri_label, value)
    api_key = Rails.configuration.api_key
    address = Rails.configuration.services
    path = "treeEdit/updateValue"
    "#{address}#{path}?apiKey=#{api_key}&runAs=#{ERB::Util.url_encode(username)}&tree=#{tree_id}&name=#{name}&valueUriLabel=#{value_uri_label}&value=#{ERB::Util.url_encode(value)}"
  end
end
