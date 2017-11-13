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
  PLACEMENT_PATH = "api/treeElement/placeTaxon"
  MOVE_PLACEMENT = "api/treeElement/moveTaxon"
  REMOVE_PLACEMENT = "api/treeElement/removeTaxon"

  def self.placement_url(params)
    @params = params
    "#{SERVICES_ADDRESS}#{PLACEMENT_PATH}?apiKey=#{Rails.configuration.api_key}"
  end

  def self.move_placement_url(username)
    "#{SERVICES_ADDRESS}#{MOVE_PLACEMENT}?apiKey=#{Rails.configuration.api_key}&as=#{username}"
  end

  def self.remove_placement_url(username)
    "#{SERVICES_ADDRESS}#{REMOVE_PLACEMENT}?apiKey=#{Rails.configuration.api_key}&as=#{username}"
  end
end
