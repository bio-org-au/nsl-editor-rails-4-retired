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
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"

  def name(name)
    name_in_tree(name)
  end

  def name_in_workspace(name)
    link_id = TreeArrangement::sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def tree_link_for_name(name)
    Rails.logger.debug("tree_link_for_name: #{name.id} #{name.full_name_html}")
    link_id = TreeArrangement::sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : Tree::EmptyTreeLink.new
  end
  
  def find_name(name)
    workspace_name = Tree::Workspace::NameIn.find(name.id)
    workspace_name.workspace_id = self.id
    workspace_name.link_id = ActiveRecord::Base.connection.select_value("select find_name_in_tree(#{name.id}, #{self.id})")
    workspace_name
  end

  def find_placement_of_name(name)
    link_id = TreeArrangement::sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def user_can_edit?(user)
    user && user.groups.include?(base_arrangement.label)
  end

  def label
    base_arrangement.label
  end

  def self.place_name_on_tree_url(username, tree_id, name, instance, parent_name, placement_type)
    if !username
      raise "must be logged on to place instances"
    end
    api_key = Rails.configuration.api_key
    address = Rails.configuration.nsl_services
    path = "treeEdit/placeNameOnTree"
    "#{address}#{path}?apiKey=#{api_key}&runAs=#{ERB::Util.url_encode(username)}&tree=#{tree_id}&name=#{name}&instance=#{instance}&parentName=#{ERB::Util.url_encode(parent_name)}&placementType=#{ERB::Util.url_encode(placement_type)}"
  end

  def self.remove_name_from_tree_url(username, tree_id, name)
    if !username
      raise "must be logged on to remove instances"
    end
    api_key = Rails.configuration.api_key
    address = Rails.configuration.nsl_services
    path = "treeEdit/removeNameFromTree"
    "#{address}#{path}?apiKey=#{api_key}&runAs=#{ERB::Util.url_encode(username)}&tree=#{tree_id}&name=#{name}"
  end


  def place_instance(username, params)
    Rails.logger.debug "--------------------------------------"
    Rails.logger.debug "Workspace::place_instance"
    Rails.logger.debug "username: #{username}"
    Rails.logger.debug "params: #{params}"
    Rails.logger.debug "--------------------------------------"
    parent_name = resolve_parent_name(params[:parent_name])
    #url = TreeArrangement::place_name_on_tree_url(username, id, params[:name_id], params[:instance_id], parent_name.nil? ? nil : parent_name.id, params[:placement_type])
    #url = Tree::AsServices.placement_url(username, id, params[:name_id], params[:instance_id], parent_name.nil? ? nil : parent_name.id, params[:placement_type])
    url = Tree::AsServices.placement_url({username: username,
                                          tree_id: id,
                                          name_id: params[:name_id],
                                          instance_id: params[:instance_id],
                                          parent_name: parent_name.nil? ? nil : parent_name.id,
                                          placement_type: params[:placement_type]})
    logger.debug url
    RestClient.post(url, accept: :json)

  rescue RestClient::BadRequest => ex
    ex.response

  end

  def resolve_parent_name(parent_name)
    parent_name = parent_name.strip
    Rails.logger.debug "resolve_parent_name"
    if parent_name && parent_name!=''
      ct = Name.where(full_name: parent_name).count
      logger.debug ct
      case ct
        when 0 then
          return {
              success: false,
              msg: [
                  {
                      status: 'warning',
                      msg: 'not found',
                      body: "Name #{parent_name} not found"
                  }
              ]
          }.to_json

        when 1 then
          pn = Name.find_by full_name: parent_name

        else
          return {
              success: false,
              msg: [
                  {
                      status: 'warn',
                      msg: 'multiple matches',
                      body: "Multiple names named #{parent_name}"
                  }
              ]
          }.to_json
      end
    else
      pn = nil
    end
    pn
  end

  def remove_instance(username, name_id)
    logger.debug "remove_instance #{id} ,#{username}, #{name_id}"

    #url = TreeArrangement::remove_name_from_tree_url(username, id, name_id)
    url = Tree::Services::Url::Remove.new({username: username,name_id: name_id, tree_id: self.id}).url
    logger.debug url
    RestClient.post(url, accept: :json)

  rescue RestClient::BadRequest => ex
    ex.response
  end
end
