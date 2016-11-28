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
    @response = @current_workspace.place_instance(username, place_name_params)
  rescue => e1
    logger.error "Error in place_name: #{e1}"
    begin
      @message = JSON.parse(first_error.response)["msg"]["msg"]
    rescue
      @message = "Services error: #{e1}"
    end
    logger.error "@message: #{@message}"
    render "place_name_error", status: 422
  end

  def remove_name_placement
    @response = @current_workspace
                .remove_instance(username,
                                 remove_name_placement_params[:name_id])
  rescue => e
    e.backtrace.each { |trace| logger.error trace }
    @message = "Services error: #{e}"
    render "remove_name_placement_error", status: 422
  end

  def update_value
    @response = TreeArrangement.find(session[:current_classification])
                               .update_value(
                                 username,
                                 params[:tree_arrangement][:name_id],
                                 params[:tree_arrangement][:value_label],
                                 params[:value]
                               )
  rescue => e
    logger.error e
    render "update_value_error", status: 422
  end

  private

  def place_name_params
    params.require(:place_name).permit(:name_id,
                                       :instance_id,
                                       :parent_name,
                                       :placement_type,
                                       :move)
  end

  def remove_name_placement_params
    params.require(:remove_placement).permit(:name_id, :instance_id, :delete)
  end
end
