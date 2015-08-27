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
  before_filter :find_instance, only: [:show, :tab, :update, :destroy]

  # GET /instances/1
  # GET /instances/1/tab/:tab
  # Sets up RHS details panel on the search results page.  Displays a specified or default tab.
  # ToDo: fix stick tabs to handle different tabs for standalone and relationships.
  def show 
    @tab = "#{ (params[:tab] && !params[:tab].blank? && params[:tab] != 'undefined') ? params[:tab] : 'tab_show_1' }"
    @tab_index = (params[:tabIndex]||'1').to_i
    @tabs_to_offer = tabs_to_offer
    render 'show', layout: false
  end

  alias tab show

  # Create the lesser version of relationship instance.
  def create_cited_by
    if instance_params[:name_id].blank?
      @instance = Instance.new
      @instance.errors.add(:base, 'You must choose a name.')
      render 'create_error', locals: {focus_on_this_id: 'instance-name-typeahead'}
    elsif instance_params[:instance_type_id].blank?
      @instance = Instance.new
      @instance.errors.add(:base, 'You must choose an instance type.')
      render 'create_error', locals: {focus_on_this_id: 'instance_instance_type_id'}
    else
      create
    end
  end

  # Create full synonymy instance.
  def create_cites_and_cited_by
    if instance_params[:cites_id].blank?
      @instance = Instance.new
      @instance.errors.add(:base, 'You must choose an instance.')
      render 'create_error', locals: {focus_on_this_id: 'instance-instance-for-name-showing-reference-typeahead'}
    elsif instance_params[:cited_by_id].blank?
      @instance = Instance.new
      @instance.errors.add(:base, 'Please refresh the tab.')
      render 'create_error', locals: {focus_on_this_id: 'instance-instance-for-name-showing-reference-typeahead'}
    elsif instance_params[:instance_type_id].blank?
      @instance = Instance.new
      @instance.errors.add(:base, 'You must choose an instance type.')
      render 'create_error', locals: {focus_on_this_id: 'instance_instance_type_id'}
    else
      cites = Instance.find(instance_params[:cites_id])
      cited_by = Instance.find(instance_params[:cited_by_id])
      the_params = {name_id: cites.name.id, 
                    cites_id: cites.id, 
                    cited_by_id: cited_by.id,
                    reference_id: cited_by.reference.id,
                    instance_type_id: instance_params[:instance_type_id],
                    verbatim_name_string: instance_params[:verbatim_name_string],
                    bhl_url: instance_params[:bhl_url],
                    page: instance_params[:page]}
      create(the_params)
    end
  end

  # Core create action.
  # Sometimes we need to massage the params - safely - before calling this create.
  def create(the_params = instance_params)
    @instance = Instance.new(the_params)
    if @instance.save_with_username(current_user.username)
      render 'create'
    else
      render 'create_error'
    end
  end

  # PUT /instances/1
  # PUT /instances/1.json
  def update
    @updated = false
    if @instance.would_change?(instance_params)
      @instance.update_attributes_with_username!(instance_params,current_user.username)
      @updated = true
    end
    render 'update.js'
  rescue => e
    logger.error(e.to_s)
    render 'update_error.js', status: :unprocessable_entity
  end

  # PUT /instances/reference/1
  # PUT /instances/reference/1.json
  def change_reference
    @updated = false
    @instance = Instance.find(params[:id])
    @instance_back_door = InstanceBackDoor.find(params[:id])
    if @instance.would_change?(instance_params)
      @instance_back_door.change_reference(instance_params)
      @updated = true
    end
    render 'update.js'
  rescue => e
    logger.error(e.to_s)
    render 'update_error.js', status: :unprocessable_entity
  end

  # DELETE /instances/1
  def destroy
    @instance.delete_as_user(current_user.username)
  rescue => e
    logger.error("Instance#destroy exception: #{e.to_s}")
    @message = e.to_s
    render 'destroy_error.js'
  end

  def typeahead_for_synonymy
    instances = Instance::AsTypeahead.for_synonymy(params[:term])
    render json: instances
  end

  # Expect instance id - of the instance user is updating.
  def typeahead_for_name_showing_references_to_update_instance
    references = []
    unless params[:instance_id].blank?
      references = Reference.find_by_sql(["select i.id,r.citation,r.year, r.pages, r.source_system, t.name instance_type from reference r  " +
                                          " inner join author a on r.author_id = a.id " +
                                          " inner join instance i on r.id = i.reference_id " +
                                          " inner join instance_type t on i.instance_type_id = t.id " +
                                          " where i.name_id = (select name_id from instance where id = ?)" +
                                          "   and i.id != ? " +
                                          "   and lower(r.citation) like lower('%'||?||'%') " +
                                          " order by r.year,a.name",
                                          params[:instance_id].to_i,params[:instance_id].to_i,params[:term]]).
                                          collect { | ref | {value: "#{ref.citation}:#{ref.year} #{'['+ref.pages+']' unless ref.pages_useless?} #{'['+ref.instance_type+']' unless ref.instance_type == 'secondary reference'} #{'['+ref.source_system.downcase+']' unless ref.source_system.blank?}", id: ref.id}}
    end
    render json: references
  end
 
  # Copy an instance with its citations
  def copy_standalone
    current_instance = Instance::AsCopier.find(params[:id])
    @instance = current_instance.copy_with_citations_to_new_reference(instance_params,current_user.username)
    @message = 'Instance was copied'
    render 'instances/copy_standalone/success.js'
  rescue => e
    logger.error("There was a problem copying that instance: #{e.to_s}")
    @message = e.to_s
    render 'instances/copy_standalone/error.js'
  end
 
 private 
  
  def find_instance
    @instance = Instance.find(params[:id])
    rescue ActiveRecord::RecordNotFound 
      flash[:alert] = "We could not find the instance." 
      redirect_to instances_path
  end

  def instance_params
    params.require(:instance).permit(:instance_type, :name_id, :reference_id, 
                   :instance_type_id, :verbatim_name_string, :page,
                   :expanded_instance_type, :cites_id, :cited_by_id, :bhl_url, :reference_id)
  end

  # Different types of instances require different sets of tabs.
  def tabs_to_offer
    offer = ['tab_show_1']
    offer << 'tab_edit'
    offer << 'tab_edit_notes'
    if @instance.simple?
      offer << 'tab_synonymy'
      offer << 'tab_unpublished_citation'
      offer << 'tab_apc_placement'
    end
    offer << 'tab_comments'
    if @instance.simple? && params['row-type'] == 'instance_as_part_of_concept_record' 
      offer << 'tab_copy_to_new_reference'
    end
    offer
  end


end

