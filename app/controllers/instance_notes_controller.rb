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
class InstanceNotesController < ApplicationController
  before_action :set_instance_note, only: [:show, :edit, :update, :destroy]

  # GET /instance_notes/1
  # GET /instance_notes/1.json
  def show
  end

  # GET /instance_notes/new
  def new
    @instance_note = InstanceNote.new
  end

  # GET /instance_notes/1/edit
  def edit
    render 'edit.js'
  end

  # POST /instance_notes
  # POST /instance_notes.json
  def create
    @message = ''
    @instance_note = InstanceNote.new(instance_note_params)

    respond_to do |format|
      if @instance_note.save_with_username(current_user.username)
        logger.debug('Save succeeded!')
        @message = "Saved"
        format.html { redirect_to @instance_note, notice: 'Instance note was successfully created.' }
        format.json { render :show, status: :created, location: @instance_note }
        format.js {}
      else
        logger.debug('Save failed!')
        @message = "Not saved"
        format.html { render :new }
        format.json { render json: @instance_note.errors, status: :unprocessable_entity }
        format.js {render :create_failed }
      end
    end
  end

  # PATCH/PUT /instance_notes/1
  # PATCH/PUT /instance_notes/1.json
  def update    
    @message = ''
    if @instance_note.instance_note_key_id.to_s != instance_note_params[:instance_note_key_id] ||
       @instance_note.value != instance_note_params[:value]
       respond_to do |format|
         if @instance_note.update_attributes_with_username!(instance_note_params,current_user.username)
           @message = 'Updated'
           format.html { redirect_to @instance_note, notice: 'Instance note was successfully updated.' }
           format.json { render :show, status: :ok, location: @instance_note }
           format.js {}
         else
           format.html { render :edit }
           format.json { render json: @instance_note.errors, status: :unprocessable_entity }
           format.js { render :update_failed }
         end
       end
    else
      @message = 'No change'
    end
  end

  # DELETE /instance_notes/1
  # DELETE /instance_notes/1.json
  def destroy
    if @instance_note.update_attributes({updated_by: current_user.username}) && @instance_note.destroy
      respond_to do |format|
        format.html { redirect_to instance_notes_url, notice: 'Instance note was successfully destroyed.' }
        format.json { head :no_content }
        format.js {}
      end
    else
      render :js => "alert('Could not delete that record.');"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instance_note
      @instance_note = InstanceNote.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def instance_note_params
      params.require(:instance_note).permit(:instance_id, :instance_note_key_id, :value, :sort_order)
    end
end
