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
  before_action :start_timer, :set_debug, :set_layout, :check_system_broadcast, :authenticate, :show_request_info

  rescue_from ActionController::InvalidAuthenticityToken, with: :show_login_page

  def show_login_page
    logger.info("Show login page - invalid authenticity token.")
    show_request_info
    if request.format == 'text/javascript'
      logger.info('Javascript request has invalide authenticity token - possibly an expired session.')
    else
      redirect_to start_sign_in_path, notice: "Please try again."
    end
  end

  def current_user
    @current_user 
  end

  protected



  def show_request_info
    logger.debug("#{'='*40}")
    logger.debug("request.format: #{request.format}")
    logger.debug("request.content_type: #{request.content_type}")
    logger.debug("#{'='*40}")
  end

  def authenticate
    logger.debug("Authenticating.")
    if session[:username].blank?
      logger.debug("User is not known.")
      logger.debug('Unauthenticated session.')
      session[:url_after_sign_in] = request.url
      respond_to do |format|
        format.html {redirect_to start_sign_in_url, notice: 'Please sign in.'}
        format.json {render partial: 'layouts/no_session.js'}
        format.js   {render partial: 'layouts/no_session.js'}
      end 
    else
      @current_user = User.new(username: session[:username],
                               full_name: session[:user_full_name],
                               groups: session[:groups])
      logger.debug("User is known: #{current_user.username}")
    end
  end


  private #####################################################################

  def set_layout
    @sidebar_width = "col-md-1 col-lg-1"
    @main_content_width = "col-md-11 col-lg-10"
    @search_result_details_width = "col-md-5 col-lg-5"
  end

  def set_debug
    @debug = false
  end
  
  def start_timer
    @start_time = Time.now
  end

  def check_system_broadcast
    @system_broadcast = ''
    file_path = Rails.configuration.path_to_broadcast_file 
    if File.exist?(file_path)
      logger.debug("System broadcast file exists at #{file_path}")
      file = File.open(file_path,'r')
      @system_broadcast = file.readline unless file.eof?
    end
  rescue => e
    logger.error("Problem with system broadcast.")
    logger.error(e.to_s)
  end

  def authorize_edit
    authorize! :edit, 'anything'
  rescue => e
    logger.error("Attempt to access unauthorized page: current_user: #{@current_user.username}; controller: #{params[:controller]}; action: #{params[:action]}.")
    redirect_to search_path
  end

  def authorize_admin
    authorize! :admin, 'anything'
  rescue => e
    logger.error("Attempt to access unauthorized page: current_user: #{@current_user.username}; controller: #{params[:controller]}; action: #{params[:action]}.")
    redirect_to search_path
  end

  def javascript_only
    unless request.format == 'text/javascript'
      logger.error("Rejecting a non-javascript request and re-directing to the search page. Is Firebug console on?")
      render text: 'javascript only', status: :service_unavailable
    end
  end

end
