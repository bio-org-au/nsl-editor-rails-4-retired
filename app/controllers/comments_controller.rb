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
class CommentsController < ApplicationController
  before_filter :authorize_edit, except: [:index, :show]
  before_filter :javascript_only  # All text/html requests should go to the search page.
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  # GET /comments
  # GET /comments.json
  def index
    @comments = Comment.all
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
  end

  # POST /comments
  # POST /comments.json
  def create
    logger.debug("Start create comment")
    @message = ''
    @comment = Comment.new(comment_params)

    respond_to do |format|
      if @comment.save_with_username(current_user.username)
        logger.debug('Save succeeded!')
        @message = "Saved"
        format.html { redirect_to @comment, notice: 'Comment created.' }
        format.json { render :show, status: :created, location: @comment }
        format.js {}
      else
        @message = "Not saved: #{@comment.errors.full_messages.first}"
        logger.error('Save failed!')
        logger.error(@message)
        format.html { render :new }
        format.json { render json: @comment.errors.to_s, status: :unprocessable_entity }
        format.js {render :create_failed }
      end
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update    
    @message = ''
    if @comment.text.to_s != comment_params[:text] 
       respond_to do |format|
         if @comment.update_attributes_with_username(comment_params,current_user.username)
           @message = 'Updated'
           format.html { redirect_to @comment, notice: 'Comment updated.' }
           format.json { render :show, status: :ok, location: @comment }
           format.js {}
         else
           @message = "Not saved. #{@comment.errors.full_messages.first}"
           format.html { render :edit }
           format.json { render json: @comment.errors, status: :unprocessable_entity }
           format.js { render :update_failed }
         end
       end
    else
      @message = 'No change'
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    if @comment.update_attributes({updated_by: current_user.username}) && @comment.destroy
      respond_to do |format|
        format.html { redirect_to comments_url, notice: 'Comment deleted.' }
        format.json { head :no_content }
        format.js {}
      end
    else
      render :js => "alert('Could not delete that record.');"
    end
  end

  private

    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.require(:comment).permit(:instance_id, :author_id, :reference_id, :name_id, :text)
    end
end

