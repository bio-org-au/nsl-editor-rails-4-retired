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
class OrchidsController < ApplicationController
  before_filter :find_orchid, only: [:show, :update, :tab]

  def show
    set_tab
    set_tab_index
    render "show", layout: false
  end

  alias tab show

  def update
    @orchids_names = OrchidsName.where(orchid_id: @orchid.id)
    stop_if_nothing_changed
    remove_unwanted_orchid_names
    orchids_name = OrchidsName.new
    orchids_name.orchid_id = @orchid.id
    orchids_name.name_id = orchid_params[:name_id]
    orchids_name.instance_id = orchid_params[:instance_id]
    orchids_name.created_by = orchids_name.updated_by = username
    orchids_name.save!
  rescue => e
    logger.error(e.to_s)
    @message = e.to_s
    render 'update_error', format: :js
  end
 
  def destroy
    throw 'destroy!'
  end

  def create
    throw 'create!'
  end

  private

  def find_orchid
    @orchid = Orchid.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the orchid."
    redirect_to orchids_path
  end

  def orchid_params
    params.require(:orchid).permit(:taxon, :name_id, :instance_id)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_show_1"
           end
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end

  def stop_if_nothing_changed
    return if @orchids_names.blank? 
    changed = false
    @orchids_names.each do |orchid_name|
      unless orchid_name.name_id == orchid_params[:name_id].to_i &&
             orchid_name.instance_id == orchid_params[:instance_id]
        changed = true
      end
    end
    raise 'no change required' unless changed
  end

  # Doesn't handle multiple name_ids being passed in params
  def remove_unwanted_orchid_names
    return if @orchids_names.blank? 
    @orchids_names.each do |orchid_name|
      unless orchid_name.name_id == orchid_params[:name_id].to_i
        orchid_name.delete
      end
    end
  end
end
