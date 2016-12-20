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
class Tree::Workspace::Placement < ActiveType::Object
  include WorkspaceParentNameResolvable
  attribute :name_id, :integer
  attribute :instance_id, :integer
  attribute :parent_name_id, :integer
  attribute :parent_name_typeahead, :string
  attribute :workspace_id, :integer
  attribute :placement_type, :string
  attribute :username, :string
  attr_reader :resolved_parent_name_id, :integer

  validates :name_id, presence: true
  validates :instance_id, presence: true
  validates :placement_type, presence: true
  validates :workspace_id, presence: true
  validates :username, presence: true
  validates :parent_name_typeahead, presence: true

  def save
    resolve_parent
    build_url
    raise errors.full_messages.first unless valid?
    RestClient.post(@url, accept: :json)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Tree::Workspace::Placement error: #{e}")
    raise
  rescue => e
    Rails.logger.error("Tree::Workspace::Placement other error: #{e}")
    raise
  end

  def build_url
    @url = Tree::AsServices.placement_url(username: username,
                                          tree_id: workspace_id,
                                          name_id: name_id,
                                          instance_id: instance_id,
                                          parent_name: @resolved_parent_name_id,
                                          placement_type: placement_type)
  end

  def resolve_parent
    @resolved_parent_name_id = resolve_parent_name(
      parent_name_id: parent_name_id,
      parent_name_typeahead: parent_name_typeahead
    )
  end
end
