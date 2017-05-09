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
  # Update name ....
  def place_name
    @placement = new_placement_for_params
    if new_placement_instance?(place_name_params)
      @placement.save
      @message = "Placed"
    elsif placement_updated_in_place?(place_name_params)
      @placement.save
      @message = "Updated"
    else
      @message = "No change"
    end
  rescue RestClient::ExceptionWithResponse => e
    logger.error("==== place_name error handler #{e.class}")
    begin
      json = JSON.parse(e.http_body)
      Rails.logger.error(ap json)
      @message_array = []
      json["msg"].each do |msg_element|
        @message_array.push msg_element["msg"]
      end
    rescue => e
      logger.error("rescue error in error")
      @message = e.to_s
    end
    logger.error "place_name error @message: #{@message}"
    render "place_name_error", status: 422
  rescue => e
    logger.error "other error"
    @message = e.to_s
  end

  def remove_name_placement
    response = @current_workspace
               .remove_instance(username,
                                remove_name_placement_params[:name_id])
    @message = "Removed"
  rescue => e
    logger.error("remove_name_placement error: #{e}")
    logger.error(response.body)
    # e.backtrace.each { |trace| logger.error trace }
    @message = e.to_s
    render "remove_name_placement_error", status: 422
  end

  def update_value
    @response = @current_workspace
                .update_value(username,
                              params[:tree_workspace][:name_id],
                              params[:tree_workspace][:value_label],
                              params[:value])
  rescue => e
    logger.error e
    render "update_value_error", status: 422
  end

  private

  def place_name_params
    params.require(:place_name)
          .permit(:name_id, :instance_id,
                  :parent_name, :parent_name_id,
                  :parent_name_typeahead_string, :placement_type,
                  :move, :update, :place, :original_name_id,
                  :original_instance_id, :original_parent_name_id,
                  :original_parent_name_typeahead_string,
                  :original_placement_type)
  end

  def remove_name_placement_params
    params.require(:remove_placement).permit(:name_id, :instance_id, :delete)
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
      workspace_id: @current_workspace.id
    )
  end
end
