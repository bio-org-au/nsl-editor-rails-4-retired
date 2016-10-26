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

  belongs_to :base_arrangement, class_name: TreeArrangement

  def find_placement_of_name(name)
    link_id = TreeArrangement::sp_find_name_in_tree(name.id, id)
    link_id ? TreeLink.find(link_id) : nil
  end

  def editableBy?(user)
    user && tree_type == 'U' && user.groups.include?(base_arrangement.label)
  end

  def derivedLabel()
    case
      when tree_type =='P' then
        label
      when tree_type == 'U' then
        base_arrangement.derivedLabel
      else
        "##{id}"
    end
  end

  def self.sp_find_name_in_tree(name_id, tree_id)
    # doing this as bind variables isn't working for me, and anyway
    # it doesn't matter because this select doen't involve a lot of planning
    connection.select_value("select find_name_in_tree(#{name_id}, #{tree_id})")
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

  def place_instance(username, name, instance, parent_name, placement_type)
    logger.debug "place_instance #{id} ,#{username}, #{name}, #{instance} ,#{parent_name} ,#{placement_type} "

    if parent_name
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

    url = TreeArrangement::place_name_on_tree_url(username, id, name, instance, pn.nil? ? nil : pn.id, placement_type)
    logger.debug url
    RestClient.post(url, accept: :json)

  rescue RestClient::BadRequest => ex
    ex.response

  end

  def remove_instance(username, name)
    logger.debug "remove_instance #{id} ,#{username}, #{name}"

    url = TreeArrangement::remove_name_from_tree_url(username, id, name)
    logger.debug url
    RestClient.post(url, accept: :json)

  rescue RestClient::BadRequest => ex
    ex.response
  end
end
