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
class ReferencesController < ApplicationController
  before_filter :authorize_edit, except: [:show]
  before_filter :find_reference, only: [:edit, :update, :destroy, :show, :citation, :generated_citation]
  
  # GET /references/1/tab/:tab
  # Sets up RHS details panel on the search results page.  Displays a specified or default tab.
  def show
    @tab = "#{ (params[:tab] && !params[:tab].blank? && params[:tab] != 'undefined') ? params[:tab] : 'tab_show_1' }"
    @tab_index = (params[:tabIndex]||'1').to_i + 2
    render 'show', layout: false
  end

  # GET /references/new
  def new
    logger.debug('New reference...')
    @reference = Reference::AsNew.default
    @no_search_result_details = true
    @tab_index = 105
    render 'new.js'
  end
  
  # GET /references/new_row
  def new_row
    @random_id = (Random.new.rand * 10000000000).to_i
    respond_to do |format|
      format.html {redirect_to search_path}
      format.js {}
    end
  end
 
  # POST /references
  def create
    @reference = Reference::AsEdited.create(reference_params,typeahead_params,current_user.username)
    render 'create.js'
  rescue => e
    logger.error("Controller:reference:create:rescuing exception #{e.to_s}")
    @error = e.to_s
    render 'create_error.js', status: :unprocessable_entity
  end

  def citation
    render partial: 'citation'
  end

  # PUT /references/1.json
  # Ajax only
  # Makes this compatible with create error processing.
  def update
    @form = params[:form][:name] if params[:form]
    @reference = Reference::AsEdited.find(params[:id])
    @message = @reference.update_if_changed(reference_params, typeahead_params,current_user.username) 
    render 'update.js'
  rescue => e
    logger.error("Controller:reference:update rescuing: #{e.to_s}")
    @message = e.to_s
    render 'update_error.js', status: :unprocessable_entity
  end

  # DELETE /references/1
  def destroy
    if @reference.update_attributes({updated_by: current_user.username}) && @reference.destroy
      render
    else
      render :js => "alert('Could not delete that record.');"
    end
  end

  # Columns such as duplicate_of_id use a typeahead search.
  def typeahead_on_citation
    references = []
    references = Reference::AsTypeahead.on_citation(params[:term]) unless params[:term].blank?
    render json: references
  end 

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def typeahead_on_citation_duplicate_of_current
    references = []
    references = Reference::AsTypeahead.on_citation(params[:term],params[:id]) unless params[:term].blank?
    render json: references
  end
 
  # Columns such as parent and duplicate_of_id use a typeahead search.
  def typeahead_on_citation_for_parent
    references = []
    references = Reference::AsTypeahead.on_citation_for_parent(params[:term],params[:id],params[:ref_type_id]) unless params[:term].blank?
    render json: references
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def typeahead_on_citation_for_duplicate
    references = []
    references = Reference::AsTypeahead.on_citation_for_duplicate(params[:term],params[:id]) unless params[:term].blank?
    render json: references
  end 

private
  
  def find_reference
    @reference = Reference.find(params[:id])
    rescue ActiveRecord::RecordNotFound 
      flash[:alert] = "We could not find the reference." 
      redirect_to references_path
  end
  
  def reference_params
    params.require(:reference).permit(:title,
                                      :display_title, 
                                      :year, 
                                      :volume, 
                                      :pages, 
                                      :edition, 
                                      :abbrev_title, 
                                      :ref_author_role_id, 
                                      :published, 
                                      :publisher, 
                                      :published_location, 
                                      :publication_date, 
                                      :doi, 
                                      :isbn, 
                                      :issn, 
                                      :bhl_url, 
                                      :tl2, 
                                      :notes, 
                                      :verbatim_reference, 
                                      :language_id, 
                                      :ref_type_id, 
                                      :verbatim_citation, 
                                      :verbatim_author) 
  end

  def typeahead_params
    params.require(:reference).permit(:parent_id, :parent_typeahead,
                                      :author_id, :author_typeahead,
                                      :duplicate_of_id, :duplicate_of_typeahead)
  end

end
