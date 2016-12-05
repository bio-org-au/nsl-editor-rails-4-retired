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
class Tree::Workspace < ActiveRecord::Base
  self.table_name = "tree_arrangement"
  self.primary_key = "id"
  default_scope { where(tree_type: "U") }
  belongs_to :base_arrangement, class_name: TreeArrangement
  belongs_to :base_tree, class_name: TreeArrangement, foreign_key: "base_arrangement_id"
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  has_many   :value_namespaces, class_name: "WorkspaceValueNamespace", foreign_key: "workspace_id"
  has_many   :workspace_instance_values, class_name: "::WorkspaceInstanceValue", foreign_key: "workspace_id"
 
  def name(name)
    name_in_tree(name)
  end

  def name_in_workspace(name)
    link_id = TreeArrangement.sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  # Find the link for the node in this tree for a particular name
  # This could be attached to the base tree
  # or, if mods occurred, it could be to the workspace.
  def find_name_node_link(name)
    Rails.logger.debug("find_name_node_link: #{name.id} #{name.full_name_html}")
    link_id = TreeArrangement.sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : Tree::EmptyTreeLink.new
  end

  def find_node(name)
    link_id = TreeArrangement.sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def find_name(name)
    workspace_name = Tree::Workspace::NameIn.find(name.id)
    workspace_name.workspace_id = id
    workspace_name.link_id = ActiveRecord::Base.connection.select_value("select find_name_in_tree(#{name.id}, #{id})")
    workspace_name
  end

  def find_placement_of_name(name)
    link_id = TreeArrangement.sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def user_can_edit?(user)
    user && user.groups.include?(base_arrangement.label)
  end

  def label
    base_arrangement.label
  end

  def self.place_name_on_tree_url(username, tree_id, name, instance, parent_name, placement_type)
    raise "must be logged on to place instances" unless username
    api_key = Rails.configuration.api_key
    address = Rails.configuration.nsl_services
    path = "treeEdit/placeNameOnTree"
    "#{address}#{path}?apiKey=#{api_key}&runAs=#{ERB::Util.url_encode(username)}&tree=#{tree_id}&name=#{name}&instance=#{instance}&parentName=#{ERB::Util.url_encode(parent_name)}&placementType=#{ERB::Util.url_encode(placement_type)}"
  end

  def self.remove_name_from_tree_url(username, tree_id, name)
    raise "must be logged on to remove instances" unless username
    api_key = Rails.configuration.api_key
    address = Rails.configuration.nsl_services
    path = "treeEdit/removeNameFromTree"
    "#{address}#{path}?apiKey=#{api_key}&runAs=#{ERB::Util.url_encode(username)}&tree=#{tree_id}&name=#{name}"
  end

  def place_instance(username, params)
    logger.debug("place instance")
    logger.debug(params.inspect)
    # parent_name = resolve_parent_name(params[:parent_name])
    logger.debug("before resolve_parent")
    parent_name_id = resolve_parent(parent_name_id: params[:parent_name_id],
                                     parent_name_typeahead_string: params[:parent_name_typeahead_string])
    logger.debug("after resolve_parent")
    logger.debug("parent_name_id: #{parent_name_id}")
    url = Tree::AsServices.placement_url(username: username,
                                         tree_id: id,
                                         name_id: params[:name_id],
                                         instance_id: params[:instance_id],
                                         parent_name: parent_name.nil? ? nil : parent_name.id,
                                         placement_type: params[:placement_type])
    RestClient.post(url, accept: :json)
  rescue => e
    logger.error("place_instance error: #{e}")
    raise
  end

  def resolve_parent_name(parent_name)
    parent_name = parent_name.strip
    Rails.logger.debug "resolve_parent_name"
    if parent_name && parent_name != ""
      ct = Name.where(full_name: parent_name).count
      logger.debug ct
      case ct
      when 0 then
        raise "Name #{parent_name} not found"
      when 1 then
        pn = Name.find_by full_name: parent_name
      else
        raise "Multiple names named #{parent_name}"
      end
    else
      raise "No name parent"
    end
  end

  def remove_instance(username, name_id)
    url = Tree::Services::Url::Remove.new(username: username,
                                          name_id: name_id,
                                          tree_id: id).url
    RestClient.post(url, accept: :json)
  rescue RestClient::BadRequest => ex
    logger.error "remove_instance error: #{e}"
    raise
  end

  def update_value(username, name, value_uri, value)
    logger.debug "update_value #{id} ,#{username}, #{name}, #{value_uri} ,'#{value}'"

    url = TreeArrangement::update_value_url(username, id, name, value_uri, value)
    logger.debug url
    RestClient.post(url, accept: :json)

  rescue RestClient::BadRequest => ex
    ex.response

  end

end
