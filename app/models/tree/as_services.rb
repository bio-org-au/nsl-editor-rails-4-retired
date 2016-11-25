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
  PLACEMENT_PATH = "treeEdit/placeNameOnTree"

  def self.placement_url(params)
    @params = params
    "#{SERVICES_ADDRESS}#{PLACEMENT_PATH}?#{params1}&#{params2}"
  end

  def self.params1
    key = "apiKey=#{Rails.configuration.api_key}"
    run_as = "runAs=#{ERB::Util.url_encode(@params[:username])}"
    tree = "tree=#{@params[:tree_id]}"
    name = "name=#{@params[:name_id]}"
    "#{key}&#{run_as}&#{tree}&#{name}"
  end

  def self.params2
    instance = "instance=#{@params[:instance_id]}"
    parent = "parentName=#{ERB::Util.url_encode(@params[:parent_name])}"
    type = "placementType=#{ERB::Util.url_encode(@params[:placement_type])}"
    "#{instance}&#{parent}&#{type}"
  end
end
