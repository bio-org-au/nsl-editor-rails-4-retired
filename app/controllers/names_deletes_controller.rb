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
class NamesDeletesController < ApplicationController
  # Confirm user wants to delete the name
  def confirm
    @names_delete = NamesDelete.new(names_delete_params)
    if @names_delete.save # i.e. successfully confirm
      logger.debug("NamesDeletes confirmed!")
      @name = Name::AsServices.find(names_delete_params[:name_id])
      logger.debug("NamesDeletes is for name: #{@name.id}")
      @name.update_attribute(:updated_by, current_user.username)
      if @name.delete_with_reason(@names_delete.assembled_reason)
        render partial: "ok.js"
      else
        @message = @name.errors.full_messages.first
        render partial: "error.js"
      end
    else
      logger.debug("NamesDeletes not saved!")
      @message = @names_delete.errors.full_messages.first
      render partial: "error.js"
    end
  rescue => e
    logger.error("Exception deleting name: #{e}")
    @message = e.to_s
    render partial: "error.js"
  end

  private

  def build_form
    @name_delete = NameDelete.new
    @no_searchbar = true
    @no_search_result_details = true
    @no_navigation = true
  end

  def names_delete_params
    params.require(:names_delete).permit(:name_id, :reason, :extra_info)
  end
end
