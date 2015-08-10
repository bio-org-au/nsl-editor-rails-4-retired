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
class UserQueriesController < ApplicationController
  before_filter :authorize_edit, except: [:index, :show]
  before_filter :find_user_query, only: [:update] 
  before_filter :find_user_query_without_search_result, only: [:show] 

  # GET /user_queries/1
  # GET /user_queries/1/tab/:tab
  # Sets up RHS details panel on the search results page.  Displays a specified or default tab.
  def show
    @tab = "#{ (params[:tab] && !params[:tab].blank? && params[:tab] != 'undefined') ? params[:tab] : 'tab_show_1' }"
    @tab_index = (params[:tabIndex]||'1').to_i
    render 'show', layout: false
  end

  # GET /user_queries/new
  # GET /user_queries/new.json
  def new
    @user_query = UserQuery.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user_query }
    end
  end

  # GET /user_queries/1/edit
  def edit
    @user_query = UserQuery.find(params[:id])
  end

  # POST /user_queries
  # POST /user_queries.json
  def create
    @user_query = UserQuery.new(params[:user_query])

    respond_to do |format|
      if @user_query.save
        format.html { redirect_to @user_query, notice: 'User query was successfully created.' }
        format.json { render json: @user_query, status: :created, location: @user_query }
      else
        format.html { render action: "new" }
        format.json { render json: @user_query.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /user_queries/1
  # PUT /user_queries/1.json
  def update
    @user_query = UserQuery.find(params[:id])

    respond_to do |format|
      if @user_query.update_attributes(params[:user_query])
        format.html { redirect_to @user_query, notice: 'User query was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user_query.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_queries/1
  # DELETE /user_queries/1.json
  def destroy
    @user_query = UserQuery.find(params[:id])
    @user_query.destroy

    respond_to do |format|
      format.html { redirect_to user_queries_url }
      format.json { head :no_content }
    end
  end
  
  private 

  def find_user_query
    @user_query = UserQuery.find(params[:id])
    rescue ActiveRecord::RecordNotFound 
      flash[:alert] = "We could not find the information." 
      redirect_to user_queries_path
  end
  
  def find_user_query_without_search_result
    # Do not include search_result in the select list 
    # - larger search_result contents slow the query down too much.
    @user_query = UserQuery.find(params[:id])
    rescue ActiveRecord::RecordNotFound 
      flash[:alert] = "We could not find the information." 
      redirect_to user_queries_path
  end

  def set_defaults
    @tab_index = 200
    @search_results = []
    @rejected_pairings = []
  end
  
end
