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

#   User can choose a workspace.
class Trees::Workspaces::CurrentController < ApplicationController
  def create
    if session[:workspace] &&
       session[:workspace]["id"] == params[:id].to_i
      head :ok
    else
      set_workspace
    end
  end

  private

  # Set instance variable for use in the request.
  # Set session variable for following requests.
  # Need both because session variable loses ActiveRecord features
  # but activerecord variable dies after the request.
  def set_workspace
    @current_workspace = Tree::Workspace.find(params[:id])
    session[:workspace] = @current_workspace
  end
end