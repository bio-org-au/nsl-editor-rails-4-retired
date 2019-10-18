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
    @orchid.name_id = orchid_params[:name_id]
    @orchid.updated_by = username
    @orchid.save!
  end

  def destroy
    throw 'destroy!'
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
end
