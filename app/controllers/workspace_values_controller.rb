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

#   Workspace trees can have value nodes for literal values
#   like distribution and comment.
class WorkspaceValuesController < ApplicationController
  def update
    logger.debug(
      "WorkspaceValuesController#update: #{workspace_value_params.inspect}")
    @workspace_value = WorkspaceValue.find(workspace_value_params[:name_node_link_id],
                                           workspace_value_params[:type_uri_id_part])
    if @workspace_value.field_value == workspace_value_params[:field_value]
      logger.debug("No change")
      @message = "No change"
    else
      @workspace_value.update(username,
                              @current_workspace.id,
                              workspace_value_params[:name_id],
                              workspace_value_params[:field_value])
      @message = "Updated"
    end
  #rescue => e
    #@message = "Error: #{e.to_s}"
    #@value_label = workspace_value_params[:value_label]
    #render "update_error", status: 400
  end

  def create
    logger.debug(
      "WorkspaceValuesController#create: #{workspace_value_params.inspect}")
    # Prepare values for rendering the form afterwards
    @name_node_tree_link = TreeLink.find(workspace_value_params[:name_node_link_id])
    @instance = @name_node_tree_link.node.instance
    # make a new workspace value object
    @workspace_value = WorkspaceValue.new_for(
      workspace_value_params[:type_uri_id_part],
      workspace_value_params[:name_id],
      workspace_value_params[:name_node_link_id]
    )
    # create it
    @workspace_value.update(username,
                            @current_workspace.id,
                            workspace_value_params[:name_id],
                            workspace_value_params[:field_value])
    @message = "Created"
  rescue => e
    @message = "Error: #{e.to_s}"
    @value_label = workspace_value_params[:value_label]
    render "update_error", status: 400
  end

  def destroy
    logger.debug(
      "WorkspaceValuesController#destroy: #{params.inspect}")
    # Prepare values for rendering the changed GUI afterwards
    @name_node_tree_link = TreeLink.find(params[:name_node_link_id])
    @instance = @name_node_tree_link.node.instance
    @workspace_value = WorkspaceValue.find(params[:name_node_link_id],
                                           params[:type_uri_id_part])
    @workspace_value.delete(username,
                            @current_workspace.id,
                            params[:name_id])
    @message = "Deleted"
  #rescue => e
    #@message = "Error: #{e.to_s}"
    #render "destroy_error", status: 400
  end

  def old_update
    logger.debug('start update_value')
    logger.debug("params[:tree_workspace][:name_id]: #{params[:tree_workspace][:name_id]}")
    logger.debug("params[:tree_workspace][:value_label]: #{params[:tree_workspace][:value_label]}")
    logger.debug("params[:value]: #{params[:value]}")
    logger.debug('update_value before call')
    @response = @current_workspace.update_value(
                                 username,
                                 params[:tree_workspace][:name_id],
                                 params[:tree_workspace][:value_label],
                                 params[:value]
                               )
  rescue => e
    logger.error e
    render "update_value_error", status: 422
  end

private
  def workspace_value_params
    params.require(:workspace_value).permit(:field_value,
                                            :name_id,
                                            :type_uri_id_part,
                                            :name_node_link_id,
                                            :value_label)
  end
end
