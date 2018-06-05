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
  before_action :set_debug,
                :start_timer,
                :check_system_broadcast,
                :authenticate,
                :check_authorization

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
      format.html {redirect_to start_sign_in_url, notice: "Please sign in."}
      format.json {render partial: "layouts/no_session.js"}
      format.js {render partial: "layouts/no_session.js"}
    end
  end

  def continue_user_session
    @current_user = User.new(username: session[:username],
                             full_name: session[:user_full_name],
                             groups: session[:groups])
    logger.info("User is known: #{@current_user.username}")
    set_working_draft_session
  end

  def set_working_draft_session
    @working_draft = nil
    if session[:draft].present? && TreeVersion.exists?(session[:draft]["id"])
      version = TreeVersion.find(session[:draft]["id"])
      if version.published
        session[:draft] = nil
      else
        @working_draft = version
      end
    end
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
