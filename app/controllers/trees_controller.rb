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
  def index;
  end

  def ng
    render "trees/#{params[:template]}", layout: false
  end

  # Move an existing taxon (inc children) under a different parent
  def move_placement
    logger.info("In move placement!")
    target = TreeVersionElement.find(move_name_params[:taxon_uri])
    parent = TreeVersionElement.find(move_name_params[:parent_element_link])
    movement = Tree::Workspace::Movement.new(username: current_user.username,
                                             target: target,
                                             parent: parent)
    movement.move
    @message = "Moved"
    render "moved_placement.js"
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "move_placement_error.js"
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "move_placement_error.js"
  end

  # Update name ....
  def place_name
    # TODO this
  end

  def remove_name_placement
    target = TreeVersionElement.find(remove_name_placement_params[:taxon_uri])
    removement = Tree::Workspace::Removement.new(username: current_user.username,
                                             target: target)
    response = removement.remove
    @message = json_result(response)
    render "removed_placement.js"
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "remove_placement_error.js"
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "remove_placement_error.js"
  end

  def update_value
    @response = @working_draft
                    .update_value(username,
                                  params[:tree_workspace][:name_id],
                                  params[:tree_workspace][:value_label],
                                  params[:value])
  rescue => e
    logger.error e
    render "update_value_error", status: 422
  end

  private

  def json_error(err)
    Rails.logger.error(err)
    json = JSON.parse(err.http_body, object_class: OpenStruct)
    json&.error || json&.to_s || err.to_s
  rescue
    err.to_s
  end

  def json_result(result)
    json = JSON.parse(result.body, object_class: OpenStruct)
    json&.payload&.message || result.to_s
  rescue
    result.to_s
  end

  def move_name_params
    params.require(:move_placement)
        .permit(:taxon_uri,
                :parent_element_link)
  end

  def place_name_params
    params.require(:place_name)
        .permit(:name_id,
                :instance_id,
                :parent_name,
                :parent_name_id,
                :parent_name_typeahead_string,
                :placement_type,
                :move,
                :update,
                :place,
                :original_name_id,
                :original_instance_id,
                :original_parent_name_id,
                :original_parent_name_typeahead_string,
                :original_placement_type)
  end

  def remove_name_placement_params
    params.require(:remove_placement).permit(:taxon_uri, :delete)
  end

  def new_placement_instance?(params)
    params[:name_id] != params[:original_name_id] ||
        params[:instance_id] != params[:original_instance_id]
  end

  def placement_updated_in_place?(params)
    params[:placement_type] != params[:original_placement_type] ||
        placement_parent_changed?(params)
  end

  def placement_parent_changed?(params)
    params[:parent_name_typeahead_string] !=
        params[:original_parent_name_typeahead_string] ||
        params[:parent_name_id] != params[:original_parent_name_id]
  end

  def new_placement_for_params
    Tree::Workspace::Placement.new(
        username: current_user.username,
        name_id: place_name_params[:name_id],
        instance_id: place_name_params[:instance_id],
        parent_name_id: place_name_params[:parent_name_id],
        parent_name_typeahead: place_name_params[:parent_name_typeahead_string],
        placement_type: place_name_params[:placement_type],
        workspace_id: @working_draft.id
    )
  end
end
