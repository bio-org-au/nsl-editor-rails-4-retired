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
class NewSearchController < ApplicationController
  before_filter :hide_details

  def search
    if params[:query_string].present? || params[:query_target].present? 
      @search = Search::Base.new(params) 
      save_search(@search)
    else
      @search = Search::Empty.new(params) 
    end
  #rescue => e
    #params[:error_message] = e.to_s
    #@search = Search::Error.new(params) 
    #save_search(@search)
  end

  def search_name_with_instances
    @search = Search::Base.new({'query_string' => "instances-for-name-id: #{params[:name_id]}"}) 
    render 'search'
  end
 
  private

  def save_search(search)
    session[:searches] ||= []
    session[:searches].push(@search.to_history)
    if session[:searches].size > 5
      session[:searches].shift
    end
  end

end
  
