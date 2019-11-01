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
class OrchidsNamesController < ApplicationController
  before_filter :find_orchids_name, only: [:show, :update]
  def create
    if params[:commit] == 'Remove'
      delete
    else
      orn = OrchidsName.new
      orn.name_id = orchids_name_params[:name_id]
      orn.orchid_id = orchids_name_params[:orchid_id]
      orn.instance_id = orchids_name_params[:instance_id]
      orn.relationship_instance_type_id = Orchid.find(orchids_name_params[:orchid_id]).riti
      orn.created_by = orn.updated_by = username
      orn.save!
    end
    @instance_id = orchids_name_params[:instance_id]
  end

  def update
    raise "No change!" if @orchids_name.relationship_instance_type_id == orchids_name_params[:relationship_instance_type_id].to_i
    @orchids_name.relationship_instance_type_id = orchids_name_params[:relationship_instance_type_id]
    @orchids_name.updated_by = username
    @orchids_name.save!
  rescue => e
    logger.error(e.to_s)
    @message = e.to_s
    render 'update_error', format: :js
  end

  def delete
    orchids_name = OrchidsName.where(orchid_id: orchids_name_params[:orchid_id])
                              .where(name_id: orchids_name_params[:name_id])
                              .where(instance_id: orchids_name_params[:instance_id])
    raise 'no such record' if orchids_name.empty?
    orchids_name.each do |orcn|
      orcn.delete
    end
  end

  private

  def orchids_name_params
    params.require(:orchid_name).permit(:orchid_id, :name_id, :instance_id, :relationship_instance_type_id)
  end

  def find_orchids_name
    @orchids_name = OrchidsName.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the orchid-name."
    redirect_to orchids_name_path
  end

end
