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

#   Trees are classification graphs for taxa.
#   There are several types of trees - see the model.
class TreesController < ApplicationController
  def index
  end

  def ng
    render "trees/#{params[:template]}", layout: false
  end

  # Move name ....
  def place_name
    logger.debug("=========================")
    logger.debug("place_name")
    logger.debug("place_name; @current_workspace.id: #{@current_workspace.id}")
    @response = @current_workspace.place_instance(username, place_name_params)
  rescue => e
    logger.error e
    logger.error e.response
    @message = JSON.parse(e.response)["msg"]["msg"]
    render "place_name_error.js"
  end

  def remove_name_placement
    @response = @current_workspace.remove_instance(username, remove_name_placement_params[:name_id])
    #@response = TreeArrangement.find(session[:current_classification]).remove_instance(
        #username,
        #params[:tree_arrangement][:name_id])

  rescue => e
    logger.error e
    render "remove_name_placement_error.js"
  end

  private

  def place_name_params
    params.require(:place_name).permit(:name_id, :instance_id, :parent_name, :placement_type, :move)
  end

  def remove_name_placement_params
    params.require(:remove_placement).permit(:name_id, :instance_id)
  end


end
