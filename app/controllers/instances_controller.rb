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
class InstancesController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :find_instance, only: [:show, :tab, :destroy]

  # GET /instances/1
  # GET /instances/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  # ToDo: sticky tabs to handle different tabs for standalone
  # and relationship instances.
  def show
    @tab = tab_or_default_tab
    @tab_index = (params[:tabIndex] || "1").to_i
    @tabs_to_offer = tabs_to_offer
    render "show", layout: false
  end

  alias tab show

  # Create the lesser version of relationship instance.
  def create_cited_by
    if instance_params[:name_id].blank?
      render_create_error("You must choose a name.",
                          "instance-name-typeahead")
    elsif instance_params[:instance_type_id].blank?
      render_create_error("You must choose an instance type.",
                          "instance_instance_type_id")
    else
      create
    end
  end

  # Create full synonymy instance.
  def create_cites_and_cited_by
    if instance_params[:cites_id].blank?
      render_cites_id_error
    elsif instance_params[:cited_by_id].blank?
      render_cited_by_id_error
    elsif instance_params[:instance_type_id].blank?
      render_instance_type_id_error
    else
      create(build_the_params)
    end
  end

  # Core create action.
  # Sometimes we need to massage the params (safely) before calling this create.
  def create(the_params = instance_params)
    @instance = Instance.new(the_params)
    if @instance.save_with_username(current_user.username)
      render "create"
    else
      render "create_error"
    end
  end

  # PUT /instances/1
  # PUT /instances/1.json
  def update
    @instance = Instance::AsEdited.find(params[:id])
    @message = @instance.update_if_changed(instance_params,
                                           current_user.username)
    render "update.js"
  rescue => e
    @message = e.to_s
    render "update_error.js", status: :unprocessable_entity
  end

  # PUT /instances/reference/1
  # PUT /instances/reference/1.json
  # Changing the reference for an instance is a special case -
  # there may/will exist denormalised ids in dependent instances.
  # We have to temporarily bypass some validations to sort it out.
  def change_reference
    @message = "No change"
    @instance = Instance.find(params[:id])
    @instance.assign_attributes(instance_params)
    make_back_door_changes if @instance.changed?
    render "update.js"
  rescue => e
    logger.error(e.to_s)
    @message = e.to_s
    render "update_error.js", status: :unprocessable_entity
  end

  def make_back_door_changes
    @instance_back_door = InstanceBackDoor.find(params[:id])
    @instance_back_door.change_reference(instance_params,
                                         current_user.username)
    @message = "Updated"
  end

  # DELETE /instances/1
  def destroy
    @instance.delete_as_user(current_user.username)
  rescue => e
    logger.error("Instance#destroy exception: #{e}")
    @message = e.to_s
    render "destroy_error.js"
  end

  def typeahead_for_synonymy
    instances = Instance::AsTypeahead.for_synonymy(params[:term])
    render json: instances
  end

  # Expect instance id - of the instance user is updating.
  def typeahead_for_name_showing_references_to_update_instance
    typeahead = Instance::AsTypeahead::ForNameShowingReferences.new(params)
    render json: typeahead.references
  end

  # Copy an instance with its citations
  def copy_standalone
    current_instance = Instance::AsCopier.find(params[:id])
    @instance = current_instance.copy_with_citations_to_new_reference(
      instance_params,
      current_user.username
    )
    @message = "Instance was copied"
    render "instances/copy_standalone/success.js"
  rescue => e
    logger.error("There was a problem copying that instance: #{e}")
    @message = e.to_s
    render "instances/copy_standalone/error.js"
  end

  private

  def find_instance
    @instance = Instance.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the instance."
    redirect_to instances_path
  end

  def instance_params
    params.require(:instance).permit(:instance_type,
                                     :name_id,
                                     :reference_id,
                                     :instance_type_id,
                                     :verbatim_name_string,
                                     :page,
                                     :cites_id,
                                     :cited_by_id,
                                     :bhl_url)
  end

  def tab_or_default_tab
    if params[:tab] && !params[:tab].blank? && params[:tab] != "undefined"
      params[:tab]
    else
      "tab_show_1"
    end
  end

  # Different types of instances require different sets of tabs.
  def tabs_to_offer
    offer = %w(tab_show_1 tab_edit tab_edit_notes)
    if @instance.simple?
      offer << "tab_synonymy"
      offer << "tab_unpublished_citation"
      offer << "tab_apc_placement"
    end
    offer << "tab_comments"
    offer << "tab_copy_to_new_reference" if offer_tab_copy_to_new_ref?
    offer
  end

  def offer_tab_copy_to_new_ref?
    @instance.simple? &&
      params["row-type"] == "instance_as_part_of_concept_record"
  end

  def render_create_error(base_error_string, focus_id)
    @instance = Instance.new
    @instance.errors.add(:base, base_error_string)
    render "create_error", locals: { focus_on_this_id: focus_id }
  end

  def render_cites_id_error
    render_create_error(
      "You must choose an instance.",
      "instance-instance-for-name-showing-reference-typeahead"
    )
  end

  def render_cited_by_id_error
    render_create_error(
      "Please refresh the tab.",
      "instance-instance-for-name-showing-reference-typeahead"
    )
  end

  def render_instance_type_id_error
    render_create_error(
      "You must choose an instance type.",
      "instance_instance_type_id"
    )
  end

  def cites_and_cited_by
    [Instance.find(instance_params[:cites_id]),
     Instance.find(instance_params[:cited_by_id])]
  end

  def build_the_params
    cites, cited_by = cites_and_cited_by
    { name_id: cites.name.id,
      cites_id: cites.id,
      cited_by_id: cited_by.id,
      reference_id: cited_by.reference.id,
      instance_type_id: instance_params[:instance_type_id],
      verbatim_name_string: instance_params[:verbatim_name_string],
      bhl_url: instance_params[:bhl_url],
      page: instance_params[:page] }
  end
end
