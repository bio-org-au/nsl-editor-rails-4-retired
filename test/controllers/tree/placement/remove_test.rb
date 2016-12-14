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

# Tree (workspace) controller test for remove placement.
class TreePlacementRemoveTest < ActionController::TestCase
  tests ::TreesController
  setup do
    @instance = instances(:usage_of_name_to_be_placed)
    @name = names(:to_be_placed)
    @parent = names(:angophora_costata)
    @workspace = tree_arrangements(:for_test)
    stub_it
  end

  def a
    "http://localhost:9090/nsl/services/treeEdit/removeNameFromTree"
  end

  def b
    "?apiKey=test-api-key&name=#{@name.id}"
  end

  def c
    "&runAs=fred&tree=#{@workspace.id}"
  end

  def stub_it
    stub_request(:post, "#{a}#{b}#{c}")
      .with(body: { "accept" => "json" },
            headers: { "Accept" => "*/*",
                       "Accept-Encoding" => "gzip, deflate",
                       "Content-Length" => "11",
                       "Content-Type" => "application/x-www-form-urlencoded",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: "", headers: {})
  end

  test "remove name from workspace" do
    @request.headers["Accept"] = "application/javascript"
    delete(:remove_name_placement,
           { id: @workspace,
             remove_placement: { name_id: @name,
                                 instance_id: @instance.id,
                                 parent_name: @parent.full_name,
                                 placement_type: "accepted" } },
           username: "fred",
           user_full_name: "Fred Jones",
           groups: %w(edit treebuilder),
           workspace: @workspace)
    assert_response :success
  end
end
