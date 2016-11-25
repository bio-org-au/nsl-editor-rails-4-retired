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

#  URL to remove a name from a tree
class Tree::Services::Url::Remove
  ADDRESS = Rails.configuration.services
  PATH = "treeEdit/removeNameFromTree"
  API_KEY = Rails.configuration.api_key
  attr_reader :url

  def initialize(params)
    @params = params
    @url = "#{ADDRESS}#{PATH}?#{credentials}&#{args}"
  end
  #  "#{address}#{path}?apiKey=#{api_key}&runAs=#{ERB::Util.url_encode(username)}&tree=#{tree_id}&name=#{name}"

  def credentials
    key = "apiKey=#{Rails.configuration.api_key}"
    run_as = "runAs=#{ERB::Util.url_encode(@params[:username])}"
    "#{key}&#{run_as}"
  end

  def args
    tree = "tree=#{@params[:tree_id]}"
    name = "name=#{@params[:name_id]}"
    "#{tree}&#{name}"
  end
end
