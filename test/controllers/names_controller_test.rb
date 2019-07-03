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
require "test_helper"

# Name controller tests not yet broken into single test files.
class NamesControllerTest < ActionController::TestCase
  setup do
    @a_species = names(:a_species)
  end

  # Wat?
  # ActionController::InvalidCrossOriginRequest: Security warning: an
  # embedded <script> tag on another site requested protected JavaScript.
  # If you know what you're doing, go ahead and disable forgery protection
  # on this action to permit cross-origin JavaScript embedding.
  #  test/controllers/names_controller_test.rb:18:in
  #  `block in <class:NamesControllerTest>'
  # test "should get new" do
  # @request.headers["Accept"] = "application/javascript"
  # get(:new,{},{username: 'fred', user_full_name: 'Fred Jones',
  # groups: ['edit']})
  # assert_response :success
  # end
  #

  #   test "should update name" do
  #     patch :update, id: @a_species, name: {  }
  #     assert_redirected_to name_path(assigns(:name))
  #   end
  #
  #   test "should destroy name" do
  #     assert_difference('Name.count', -1) do
  #       delete :destroy, id: @a_species
  #     end
  #
  #     assert_redirected_to names_path
  #   end
end
