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
# require 'test_helper'
#
# Name Tags controller tests
# class NameTagsControllerTest < ActionController::TestCase
#   setup do
#     @name_tag = name_tags(:one)
#   end
#
#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:name_tags)
#   end
#
#   test "should get new" do
#     get :new
#     assert_response :success
#   end
#
#   test "should create name_tag" do
#     assert_difference('NameTag.count') do
#       post :create, name_tag: { name: @name_tag.name }
#     end
#
#     assert_redirected_to name_tag_path(assigns(:name_tag))
#   end
#
#   test "should show name_tag" do
#     get :show, id: @name_tag
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get :edit, id: @name_tag
#     assert_response :success
#   end
#
#   test "should update name_tag" do
#     patch :update, id: @name_tag, name_tag: { name: @name_tag.name }
#     assert_redirected_to name_tag_path(assigns(:name_tag))
#   end
#
#   test "should destroy name_tag" do
#     assert_difference('NameTag.count', -1) do
#       delete :destroy, id: @name_tag
#     end
#
#     assert_redirected_to name_tags_path
#   end
# end
