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
#
class TreesController < ApplicationController
  def index
  end

  def ng
    render "trees/#{params[:template]}", layout: false
  end

  def select_classification
    session[:current_classification] = params[:classification]
    redirect_to controller: 'search', action: 'search'
  end

  def place_name
    @response = TreeArrangement.find(session[:current_classification]).place_instance(
        username,
        params[:tree_arrangement][:name_id],
        params[:tree_arrangement][:instance_id],
        params[:parent_name],
        params[:placement_type])

  rescue => e
    logger.error e
    logger.info e.response
    render "place_name_error.js"
  end

  def remove_name_placement
    @response = TreeArrangement.find(session[:current_classification]).remove_instance(
        username,
        params[:tree_arrangement][:name_id])

  rescue => e
    logger.error e
    render "remove_name_placement_error.js"
  end

end
