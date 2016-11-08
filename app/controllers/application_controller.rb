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
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :start_timer, :set_debug, :check_system_broadcast,
                :authenticate, :check_authorization

  rescue_from ActionController::InvalidAuthenticityToken, with: :show_login_page
  rescue_from CanCan::AccessDenied do |_exception|
    logger.error("Access Denied")
    head :forbidden
  end

  def show_login_page
    logger.info("Show login page - invalid authenticity token.")
    if request.format == "text/javascript"
      logger.info('JavaScript request with invalid authenticity token\
                  - expired session?')
    else
      redirect_to start_sign_in_path, notice: "Please try again."
    end
  end

  attr_reader :current_user

  def username
    @current_user.username
  end

  protected

  def check_authorization
    pseudo_action = if params[:tab].present?
                      params[:tab]
                    else
                      params[:action]
                    end
    logger.info("check_authorization: pseudo_action: #{pseudo_action}")
    authorize!(params[:controller], pseudo_action)
  end

  def authenticate
    if session[:username].blank?
      ask_user_to_sign_in
    else
      continue_user_session
    end
  end

  private #####################################################################

  def ask_user_to_sign_in
    session[:url_after_sign_in] = request.url
    respond_to do |format|
      format.html { redirect_to start_sign_in_url, notice: "Please sign in." }
      format.json { render partial: "layouts/no_session.js" }
      format.js   { render partial: "layouts/no_session.js" }
    end
  end

  def continue_user_session
    @current_user = User.new(username: session[:username],
                             full_name: session[:user_full_name],
                             groups: session[:groups])

    @visible_classifications = [  ]
    # TODO: check that this classification is visible to this user

    if session[:current_classification]
      @current_classification = TreeArrangement.find(session[:current_classification])
      if @current_classification.tree_type == 'U'
        # a workspace is editable if the user is a member of the group
        # named by the workspace's base classification
        t = TreeArrangement.find(@current_classification.base_arrangement_id)
        @current_classification_editable = @current_user.groups.include? t.label
      else
        # only workspaces are editable
        @current_classification_editable = false
      end
    else
      @current_classification = nil
      @current_classification_editable = false
    end


    TreeArrangement.where(tree_type: 'P').order(:label).each  do |t|
      if @current_user.groups.include?(t.label) || t.shared

        tree = {
          tree: t,
          editable: t.editableBy?(@current_user),
          selected: @current_classification == t,
          workspaces: []
        }

        @visible_classifications <<  tree

        TreeArrangement.where(tree_type: 'U', base_arrangement_id: t.id).each  do |w|
          if @current_user.groups.include?(t.label) || w.shared
            workspace = {
              workspace: w,
              editable: @current_user.groups.include?(t.label),
              selected: @current_classification == w
            }
            tree[:workspaces] << workspace
          end
        end
      end


    end


    logger.debug("User is known: #{current_user.username}")
  end

  def set_debug
    @debug = false
  end

  def start_timer
    @start_time = Time.now
  end

  def check_system_broadcast
    @system_broadcast = ""
    file_path = Rails.configuration.path_to_broadcast_file
    if File.exist?(file_path)
      logger.debug("System broadcast file exists at #{file_path}")
      file = File.open(file_path, "r")
      @system_broadcast = file.readline unless file.eof?
    end
  rescue => e
    logger.error("Problem with system broadcast.")
    logger.error(e.to_s)
  end

  # Could not get this to work with a guard clause.
  def javascript_only
    unless request.format == "text/javascript"
      logger.error('Rejecting a non-JavaScript request and re-directing \
                   to the search page. Is Firebug console on?')
      render text: "JavaScript only", status: :service_unavailable
    end
  end

  def hide_details
    @no_search_result_details = true
  end

  def empty_search
    @search = Search::Empty.new(params)
  end

  def pick_a_tab(default_tab = "tab_show_1")
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             default_tab
           end
  end

  def pick_a_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end
end
