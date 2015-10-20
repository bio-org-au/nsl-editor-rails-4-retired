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
    session[:searches] ||= []
    @search = params[:query_string].present? ? Search::Base.new(params) : Search::Empty.new(params) 
    #session[:searches].push(params[:query_string])
    session[:searches].push(@search.to_history)
  rescue => e
    @search = Search::Error.new(params) 
    session[:searches].push(@search.to_history)
    @error = e.to_s
  end

  def search_name_with_instances
    @search = Search::Base.new({'query_string' => "instances-for-name-id: #{params[:name_id]}"}) 
    render 'search'
  end

end
  
