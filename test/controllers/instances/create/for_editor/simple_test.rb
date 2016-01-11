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

class InstancesCreateByEditorTest < ActionController::TestCase
  tests InstancesController

  test "editor should be able to call create" do
    skip # the current code means the create method should not be called directly - see create_cited_by, create_cites_and_cited_by
    # so I'd prefer the create method was private, but making it private broke lots of things.
    # name = names(:a_species)
    # reference = references(:a_book)
    # @request.headers["Accept"] = "application/javascript"
    # assert_no_difference('Instance.count') do
    # post(:create, {instance: {}}, {username: 'fred', user_full_name: 'Fred Jones', groups: ['edit']})
    # end
    # assert_response :success
  end
end
