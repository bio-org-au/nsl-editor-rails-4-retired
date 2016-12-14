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

# Tree (workspace) controller test for create placement.
class WorkspaceValuesUpdateSimpleTest < ActionController::TestCase
  tests ::WorkspaceValuesController
  setup do
    @instance = instances(:usage_of_name_to_be_placed)
    @name = names(:to_be_placed)
    @parent = names(:angophora_costata)
    @workspace = tree_arrangements(:for_test)
    #stub_it
  end

  def a
    "http://localhost:9090/nsl/services/treeEdit/placeNameOnTree"
  end

  def b
    "?apiKey=test-api-key&instance=#{@instance.id}&name=#{@name.id}"
  end

  def c
    "&parentName=#{@parent.id}&placementType=accepted&runAs=fred&"
  end

  def d
    "tree=#{@workspace.id}"
  end

  def user_agent
    "rest-client/2.0.0 (darwin16.1.0 x86_64) ruby/2.3.0p0"
  end

  def stub_it
    stub_request(:post, "#{a}#{b}#{c}#{d}")
      .with(body: { "accept" => "json" },
            headers: { "Accept" => "*/*",
                       "Accept-Encoding" => "gzip, deflate",
                       "Content-Length" => "11",
                       "Content-Type" => "application/x-www-form-urlencoded",
                       "Host" => "localhost:9090",
                       "User-Agent" => user_agent })
      .to_return(status: 200, body: "", headers: {})
  end

  test "place name in workspace" do
    skip "Need to set up workspace value via mock or similar"
    WorkspaceValue = Minitest::Mock.new
    def WorkspaceValue.find; new WorkspaceValue; end

    @request.headers["Accept"] = "application/javascript"
    patch(:update, { workspace_value: { field_value: "new value",
                                        name_id: @name,
                                        name_node_link_id: 2,
                                        value_label: "not important",
                                        type_uri_id_part: "accepted" } },
          username: "fred",
          user_full_name: "Fred Jones",
          groups: %w(edit treebuilder),
          workspace: @workspace)
    assert_response :success
  end
end
