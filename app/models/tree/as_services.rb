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
  LINKER_ADDRESS = Rails.configuration.nsl_linker
  PLACEMENT_PATH = "api/treeElement/placeElement"
  REPLACE_ELEMENT = "api/treeElement/replaceElement"
  REMOVE_PLACEMENT = "api/treeElement/removeElement"
  API_KEY = "apiKey=#{Rails.configuration.api_key}"
  PREFERRED_LINK = "broker/preferredLink"

  def self.placement_url(username)
    "#{SERVICES_ADDRESS}#{PLACEMENT_PATH}?#{API_KEY}&as=#{username}"
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
end
