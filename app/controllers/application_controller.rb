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
  before_filter :start_timer, :set_debug
  before_action :set_layout, :check_system_broadcast
  before_filter :authenticate, :show_request_info

  rescue_from ActionController::InvalidAuthenticityToken, with: :show_login_page

  APNI_QUERY_PATH_FOR_NAME = "http://www.anbg.gov.au/cgi-bin/apni?00TAXON_NAME=" 

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

    
  def reassemble_saved_query
    user_query = UserQuery.find(params[:user_query])
    params[:query] = user_query.search_terms
    @search_results = user_query.search_result
  end
  private :reassemble_saved_query

  def set_debug
    @debug = false
  end
  
  def replay_latest_session_query
    unless session[:instance_queries].blank?
      params[:query] = session[:instance_queries].last.gsub(/save:[^ ]*/,'')
      run_search
    end
  end
  private :replay_latest_session_query

  def start_timer
    @start_time = Time.now
  end

  def set_defaults
    @search_results,@rejected_pairings,@limited,@save_search,@search_info  = [],false,[],false,false,''
  end

  def save_search?
    save_search = !params[:query].match(/save:/).nil?
    return save_search
  end

  def run_search
    logger.debug('run_search') 
    @tab_index = 200
    @save_search = false
    add_query_to_session(10)
    if params[:query].blank?
      set_defaults
    elsif save_search?
      save_search
      @save_search = true
    else
      @search_results ||= []
      @rejected_pairings ||= []
      @limited ||= false
      @focus_anchor_id ||= ''
      @search_info ||= ''
      search_results,
        rejected_pairings,
        limited,
        focus_anchor_id,
        search_info,
        save_search  = do_the_search
      @search_results.concat(search_results)
      @rejected_pairings += rejected_pairings
      @limited = limited
      @focus_anchor_id = focus_anchor_id
      @search_info += search_info unless search_info.blank?
    end
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
