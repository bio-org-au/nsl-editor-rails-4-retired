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

#  Tree services
class Tree::AsServices
  SERVICES_ADDRESS = Rails.configuration.services
  CLIENT_SIDE_SERVICES = Rails.configuration.services_clientside_root_url
  LINKER_ADDRESS = Rails.configuration.nsl_linker
  PLACEMENT_PATH = "api/treeElement/placeElement"
  TOP_PLACEMENT_PATH = "api/treeElement/placeTopElement"
  REPLACE_ELEMENT = "api/treeElement/replaceElement"
  REPARENT_ELEMENT = "api/treeElement/changeParentElement"
  REMOVE_PLACEMENT = "api/treeElement/removeElement"
  UPDATE_PROFILE = "api/treeElement/editElementProfile"
  UPDATE_EXCLUDED = "api/treeElement/editElementStatus"
  CREATE_VERSION = "api/tree/createVersion"
  PUBLISH_VERSION = "api/treeVersion/publish"

  DIFF_LINK = "treeVersion/diff"
  VAL_LINK = "treeVersion/validate"
  SYN_LINK = "tree/eventReport"
  VAL_SYN_LINK = "tree/checkCurrentSynonymy"
  SYN_UPDATE_LINK = "tree-element/update-synonymy-by-event"

  API_KEY = "apiKey=#{Rails.configuration.api_key}"
  PREFERRED_LINK = "broker/preferredLink"
  ADD_IDENTIFIER = "admin/addIdentifier"

  def self.placement_url(username, top)
    if top
      "#{SERVICES_ADDRESS}#{TOP_PLACEMENT_PATH}?#{API_KEY}&as=#{username}"
    else
      "#{SERVICES_ADDRESS}#{PLACEMENT_PATH}?#{API_KEY}&as=#{username}"
    end
  end

  def self.reparent_placement_url(username)
    "#{SERVICES_ADDRESS}#{REPARENT_ELEMENT}?#{API_KEY}&as=#{username}"
  end

  def self.replace_placement_url(username)
    "#{SERVICES_ADDRESS}#{REPLACE_ELEMENT}?#{API_KEY}&as=#{username}"
  end

  def self.remove_placement_url(username)
    "#{SERVICES_ADDRESS}#{REMOVE_PLACEMENT}?#{API_KEY}&as=#{username}"
  end

  def self.preferred_link_url(instance_id)
    ShardConfig.name_space
    target = "nameSpace=#{ShardConfig.name_space.downcase}&objectType=instance&idNumber=#{instance_id}"
    "#{LINKER_ADDRESS}#{PREFERRED_LINK}?#{target}"
  end

  def self.profile_url(username)
    "#{SERVICES_ADDRESS}#{UPDATE_PROFILE}?#{API_KEY}&as=#{username}"
  end

  def self.excluded_url(username)
    "#{SERVICES_ADDRESS}#{UPDATE_EXCLUDED}?#{API_KEY}&as=#{username}"
  end

  def self.create_version_url(username)
    "#{SERVICES_ADDRESS}#{CREATE_VERSION}?#{API_KEY}&as=#{username}"
  end

  def self.publish_version_url(username)
    "#{SERVICES_ADDRESS}#{PUBLISH_VERSION}?#{API_KEY}&as=#{username}"
  end

  def self.add_instance_identifier_url(instance_id)
    "#{LINKER_ADDRESS}#{ADD_IDENTIFIER}?#{API_KEY}&#{add_identity_param_string(instance_id)}"
  end

  def self.add_identity_param_string(instance_id)
    "nameSpace=#{ShardConfig.name_space.downcase}&objectType=instance&idNumber=#{instance_id}&versionNumber=&uri="
  end

  def self.instance_url(instance_id)
    url = preferred_link_url(instance_id)
    Rails.logger.info "calling #{url}"
    response = RestClient.get(url, {content_type: :json, accept: :json})
    json = JSON.parse(response.body, object_class: OpenStruct)
    json.link
  rescue RestClient::ExceptionWithResponse => rest_client_exception
    Rails.logger.warn("Tree::Workspace::Placement error: #{rest_client_exception.response}")
    if rest_client_exception.response.code == 404
      add_instance_link(instance_id)
    end
  rescue => e
    Rails.logger.error("Tree::Workspace::Placement error: #{e}")
    raise
  end

  def self.add_instance_link(instance_id)
    url = add_instance_identifier_url(instance_id)
    Rails.logger.info "calling #{url}"
    response = RestClient.put(url, {content_type: :json, accept: :json})
    json = JSON.parse(response.body, object_class: OpenStruct)
    json.preferredURI
  rescue => e
    Rails.logger.error("Tree::Workspace::Placement error: #{e.response}")
    raise
  end

  def self.diff_link(v1, v2)
    "#{CLIENT_SIDE_SERVICES}#{DIFF_LINK}?v1=#{v1}&v2=#{v2}&embed=true"
  end

  def self.syn_link(tree)
    "#{CLIENT_SIDE_SERVICES}#{SYN_LINK}?treeId=#{tree}&embed=true"
  end

  def self.syn_update_link(username)
    "#{CLIENT_SIDE_SERVICES}#{SYN_UPDATE_LINK}?#{API_KEY}&as=#{username}"
  end

  def self.update_synonymy(events, username)
    url = syn_update_link(username)
    Rails.logger.info "calling #{url}"
    RestClient.post(url, {events: events}, {accept: :json})
  end

  def self.val_syn_link(tree)
    "#{CLIENT_SIDE_SERVICES}#{VAL_SYN_LINK}?treeId=#{tree}&embed=true"
  end

  def self.val_link(version)
    "#{CLIENT_SIDE_SERVICES}#{VAL_LINK}?version=#{version}&embed=true"
  end

end
