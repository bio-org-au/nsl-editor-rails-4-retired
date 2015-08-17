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
require 'open-uri'

class NamesController < ApplicationController

  include OpenURI
  before_filter :authorize_edit, except: [:index, :show, :rules]
  before_filter :javascript_only, except: [:rules]  # All text/html requests should go to the search page.
  before_filter :find_name, only: [:show, :edit_as_category, :refresh]

  # GET /names/1
  # GET /names/1.json
  # Sets up RHS details panel on the search results page.  Displays a specified or default tab.
  def show
    @apni_query_path = APNI_QUERY_PATH_FOR_NAME
    @tab = "#{ (params[:tab] && !params[:tab].blank? && params[:tab] != 'undefined') ? params[:tab] : 'tab_details' }"
    @tab = authorized_tab(@tab)
    @tab_index = (params[:tabIndex]||'1').to_i
    if params[:change_category_to].present?
      @name.change_category_to = 'scientific' 
    end
    if params[:tab].match(/\Atab_instances\z/)
      @instance = Instance.new if params[:tab].match(/\Atab_instances\z/)
      @instance.name = @name
    end
    render 'show', layout: false
  end

  # Used on references - new instance tab
  def typeahead_on_full_name
    names = []
    names = Name::AsTypeahead.on_full_name(params[:term].gsub(/\*/,'%')) unless params[:term].blank?
    render json: names
  end

  # For the typeahead search.
  def name_parent_suggestions
    logger.debug('name_parent_suggestions...')
    names = []
    if params[:term].present? && params[:rank_id].present? && params[:rank_id] != 'undefined'
      names = Name::AsTypeahead.name_parent_suggestions(params[:term],params[:name_id], params[:rank_id])
    end
    render json: names
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def cultivar_parent_suggestions
    names = []
    names = Name::AsTypeahead.cultivar_parent_suggestions(params[:term],params[:name_id],params[:rank_id]) if params[:term].present?
    render json: names
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def hybrid_parent_suggestions
    names = []
    names = Name::AsTypeahead.hybrid_parent_suggestions(params[:term],params[:name_id],params[:rank_id]) if params[:term].present?
    render json: names
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def duplicate_suggestions
    names = []
    names = Name::AsTypeahead.duplicate_suggestions(params[:term],params[:name_id]) if params[:term].present? && params[:name_id].present?
    render json: names
  end

  def edit_as_category
    logger.debug('edit_as_category')
    @apni_query_path = APNI_QUERY_PATH_FOR_NAME
    @tab = 'tab_edit'
    @tab_index = 1 
    if params[:new_category].present?
      logger.debug("there is a params[:new_category]: #{params[:new_category]}")
      @name.change_category_to = params[:new_category]
    end
    render 'show', layout: false
  end

  # GET /names/new_row
  def new_row
    @random_id = (Random.new.rand * 10000000000).to_i
    @category = params[:type].gsub(/-/,' ')
    logger.debug("@category: #{@category}")
    respond_to do |format|
      format.html {redirect_to search_path}
      format.js {}
    end
  end
  
  # GET /names/new
  def new
    logger.debug('new')
    case params[:category]
    when 'scientific'
      @name = Name::AsNew.scientific
    when 'hybrid formula'
      @name = Name::AsNew.scientific_hybrid
    when 'hybrid formula unknown 2nd parent'
      @name = Name::AsNew.scientific_hybrid_unknown_2nd_parent
    when 'cultivar hybrid'
      @name = Name::AsNew.cultivar_hybrid
    when 'cultivar'
      @name = Name::AsNew.cultivar
    else
      @name = Name::AsNew.other
    end
    @no_search_result_details = true
    render 'new.js'
  end

  # POST /names
  def create
    @name = Name::AsEdited.create(name_params,typeahead_params,current_user.username)
    render 'create.js'
  rescue => e
    logger.error("Controller:Names:create:rescuing exception #{e.to_s}")
    @error = e.to_s
    render 'create_error.js', status: :unprocessable_entity
  end

  # PUT /names/1.json
  # Ajax only.
  def update
    @name = Name::AsEdited.find(params[:id])
    @message = @name.update_if_changed(name_params,typeahead_params,current_user.username)
    render 'update.js'
  rescue => e
    @message = e.to_s
    render 'update_error.js', status: :unprocessable_entity
  end
 
  # DELETE /names/1
  # DELETE /names/1.json
  def destroy
    raise 'problem'
    @name = find_name_as_services
    if @name.delete
      render
    else
      render 'destroy_error'
    end
  end

  def rules
    @no_search_result_details = true
  end

  def copy
    logger.debug('copy')
    current_name = Name::AsCopier.find(params[:id])
    @name = current_name.copy_with_username(name_params[:name_element],current_user.username)
    render 'names/copy/success.js'
  rescue => e
    @message = e.to_s
    render 'names/copy/error.js'
  end

  def refresh
    @name.set_names!
    render 'refresh.js'
  end

  private 
 
  def find_name
    @name = Name.find(params[:id])
  rescue ActiveRecord::RecordNotFound 
    flash[:alert] = "Could not find the name." 
    redirect_to names_path
  end

  def find_name_as_services
    @name = Name::AsServices.find(params[:id])
  rescue ActiveRecord::RecordNotFound 
    flash[:alert] = "Could not find the name." 
    redirect_to names_path
  end

  def name_params
      params.require(:name).permit(:name_status_id, :name_rank_id, :name_type_id, :name_element, :verbatim_rank) 
  end

  def typeahead_params
    params.require(:name).permit(:author_id,
                                 :ex_author_id, 
                                 :base_author_id, 
                                 :ex_base_author_id, 
                                 :sanctioning_author_id, 
                                 :author_typeahead,
                                 :ex_author_typeahead,
                                 :base_author_typeahead,
                                 :ex_base_author_typeahead,
                                 :sanctioning_author_typeahead,
                                 :parent_id,
                                 :second_parent_id,
                                 :parent_typeahead,
                                 :second_parent_typeahead,
                                 :duplicate_of_id,
                                 :duplicate_of_typeahead)
  end

  def authorized_tab(tab_name,read_only_tab = 'tab_details')
    if can? :edit, 'anything'
      logger.debug('Authorized to edit anything.')
      tab_name
    else
      logger.debug('NOT authorized to edit anything.')
      read_only_tab
    end
  end
    
end

