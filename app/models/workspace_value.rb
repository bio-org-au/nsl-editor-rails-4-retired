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
# Values exist as links and nodes in workspace trees.
#
# Note: the tree_value_uri table is intended to let you
# define new value data types.  But there are certain limits
# in what it allows for.  E.g. beyond a data type of string, it
# cannot distinguish between single-line field strings and multi-line
# strings.
#
# The compromise we have at the moment is to use tree_value_uri, but
# limit it to 2 essential fields:
#
#    * distribution
#    * comment
#
# Distribution is a single-line field.
#
# Comment is a multi-line field.
class WorkspaceValue < ActiveRecord::Base
  self.table_name = "workspace_value_vw"
  belongs_to :tree_link, foreign_key: "name_node_link_id"
  belongs_to :workspace, class_name: "tree/workspace"

  COMMENT = "comment".freeze
  DISTRIBUTION = "distribution".freeze

  # See class comment
  def multiline?
    field_name.downcase.match(/#{COMMENT}/)
  end

  def create(username, current_workspace_id, name_id, value)
    url = TreeArrangement.update_value_url(username,
                                           current_workspace_id,
                                           name_id,
                                           value_label,
                                           value)
    RestClient.post(url, accept: :json)
  rescue RestClient::BadRequest => e
    logger.error(e.to_s)
    raise e.to_s
  end

  def update(username, current_workspace_id, name_id, value)
    url = TreeArrangement.update_value_url(username,
                                           current_workspace_id,
                                           name_id,
                                           value_label,
                                           value)
    RestClient.post(url, accept: :json)
  rescue RestClient::BadRequest => e
    logger.error(e.to_s)
    raise e.to_s
  end

  # Delete by sending an empty value to the update service.
  def delete(username, current_workspace_id, name_id)
    update(username, current_workspace_id, name_id, '')
  end

  def self.find(name_node_link_id, type_uri_id_part)
    results = WorkspaceValue.where(name_node_link_id: name_node_link_id,
                                   type_uri_id_part: type_uri_id_part)
    throw "Expected to find only one workspace value" if results.size > 1
    throw "Expected to find workspace value" if results.empty?
    results.first
  end

  def self.new_distribution(name_id, name_node_link_id)
    record = self.new
    record.field_name = "distribution"
    record.name_id = name_id
    record.name_node_link_id = name_node_link_id
    record.type_uri_id_part = "distribution"
    record.value_label = "apc-distribution"
    record
  end

  def self.new_for(type_value_id_part, name_id, name_node_link_id)
    if type_value_id_part == "distribution"
      self.new_distribution(name_id, name_node_link_id)
    else
      # ToDo: build method
      self.new_comment(name_id, name_node_link_id)
    end
  end
end
