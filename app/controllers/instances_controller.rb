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

#   Controls instances.
class InstancesController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :find_instance, only: [:show, :tab, :destroy]
  CONCEPT_WARNING = "Validation failed: This concept includes an accepted name \
as a synonym"
  EXTRA_PRIMARY_WARNING = "Validation failed: This would result in multiple primary instances"

  # GET /instances/1
  # GET /instances/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    @tab = tab_or_default_tab
    @tab_index = (params[:tabIndex] || "1").to_i
    @tabs_to_offer = tabs_to_offer
    # Really only need to do this if the "class" tab is chosen.
    # ToDo: do this only when needed.
    unless @current_workspace.blank?
      @name_node_tree_link = @current_workspace.find_name_node_link(@instance.name)
    end
    render "show", layout: false
  end

  alias tab show

  # Create the lesser version of relationship instance.
  def create_cited_by
    resolve_unpub_citation_name_id(instance_params[:name_id],
                                   instance_name_params[:name_typeahead])
    if instance_params[:name_id].blank?
      render_create_error("You must choose a name.", "instance-name-typeahead")
    elsif instance_params[:instance_type_id].blank?
      render_create_error("You must choose an instance type.",
                          "instance_instance_type_id")
    else
      create
    end
  rescue => e
    render_create_error(e.to_s, "instance-name-typeahead")
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
    @instance.concept_warning_bypassed =
      instance_params[:concept_warning_bypassed] == "1"
    @instance.extra_primary_override =
      instance_params[:extra_primary_override] == "1"
    @instance.save_with_username(current_user.username)
    render "create"
  rescue ActiveRecord::RecordNotUnique
    handle_not_unique
  rescue => e
    handle_other_errors(e)
  end

  def handle_not_unique
    @message = "Error: duplicate record"
    render "create_error.js", status: :unprocessable_entity
  end
  private :handle_not_unique

  def handle_other_errors(e)
    @allow_bypass = e.to_s.match(/\A#{CONCEPT_WARNING}\z/)
    @multiple_primary_warning =
      e.to_s.match(/#{Instance::MULTIPLE_PRIMARY_WARNING}\z/)
    @message = e.to_s
    logger.error("Error in handle_other_errors: #{@message}")
    render "create_error.js", status: :unprocessable_entity
  end
  private :handle_other_errors

  # PUT /instances/1
  # PUT /instances/1.json
  def update
    @instance = Instance::AsEdited.find(params[:id])
    @instance.extra_primary_override =
      instance_params[:extra_primary_override] == "1"
    @message = @instance.update_if_changed(instance_params,
                                           current_user.username)
    render "update.js"
  rescue => e
    @multiple_primary_warning =
      e.to_s.match(/#{Instance::MULTIPLE_PRIMARY_WARNING}\z/)
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
    render "destroy_error.js", status: 422
  end

  def typeahead_for_synonymy
    instances = Instance::AsTypeahead.for_synonymy(params[:term])
    render json: instances
  end

  # Expect instance id - of the instance user is updating.
  # Synonym Edit tab.
  def typeahead_for_name_showing_references_to_update_instance
    typeahead = Instance::AsTypeahead::ForNameShowingReferences.new(params)
    render json: typeahead.references
  end

  # Copy an instance with its citations
  def copy_standalone
    current_instance = Instance::AsCopier.find(params[:id])
    current_instance.extra_primary_override =
      instance_params[:extra_primary_override] == "1"
    @instance = current_instance.copy_with_citations_to_new_reference(
      instance_params, current_user.username
    )
    @message = "Instance was copied"
    render "instances/copy_standalone/success.js"
  rescue => e
    logger.error("There was a problem copying that instance: #{e}")
    @multiple_primary_warning =
      e.to_s.match(/#{Instance::MULTIPLE_PRIMARY_WARNING}\z/)
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
                                     :bhl_url,
                                     :concept_warning_bypassed,
                                     :extra_primary_override)
  end

  def instance_name_params
    params.require(:instance).permit(:name_id, :name_typeahead)
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
      # TODO: remove apc placement tab
      offer << "tab_apc_placement"
      offer << "tab_classification"
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
    @message = base_error_string
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
    build_them(cites, cited_by)
  end

  def build_them(cites, cited_by)
    { name_id: cites.name.id,
      cites_id: cites.id,
      cited_by_id: cited_by.id,
      reference_id: cited_by.reference.id,
      instance_type_id: instance_params[:instance_type_id],
      verbatim_name_string: instance_params[:verbatim_name_string],
      bhl_url: instance_params[:bhl_url],
      page: instance_params[:page] }
  end

  def resolve_unpub_citation_name_id(name_id, name_typeahead)
    return unless instance_params[:name_id].blank?
    params[:instance][:name_id] = Name::AsResolvedTypeahead::ForUnpubCitationInstance.new(name_id, name_typeahead).value
  end
end
