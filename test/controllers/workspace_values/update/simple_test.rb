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
    @name_to_be_updated = names(:angophora_costata)
    @name_node_link_id = 22
    mock_call_to_find_workspace_value
    stub_for_post_to_update_value
  end

  def path
    "http://localhost:9090/nsl/services/treeEdit"
  end

  def api_key
    "apiKey=test-api-key"
  end

  def name_arg
    "name=605492557"
  end

  def tree
    "tree=#{@workspace.id}"
  end

  def value
    "value=new%20value"
  end

  def as
    "runAs=fred&"
  end

  def stub_for_post_to_update_value
    params = "#{api_key}&#{name_arg}&#{tree}&#{as}&#{value}&valueUriLabel="
    stub_request(:post, "#{path}/updateValue?#{params}")
      .with(body: { "accept" => "json" },
            headers: { "Accept" => "*/*",
                       "Accept-Encoding" => "gzip, deflate",
                       "Content-Length" => "11",
                       "Content-Type" => "application/x-www-form-urlencoded",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: "", headers: {})
  end

  def mock_call_to_find_workspace_value
    instance = instances(:britten_created_angophora_costata)
    workspace_value = WorkspaceValue.new
    workspace_value.instance_id = instance.id
    workspace_value.name_id = @name.id
    workspace_value.workspace_id = @workspace.id
    workspace_value.type_uri_id_part = "distribution"
    workspace_value.name_node_link_id = @name_node_link_id
    WorkspaceValue.expects(:find)
                  .with(@name_node_link_id.to_s, "accepted")
                  .returns(workspace_value)
  end

  test "place name in workspace" do
    @request.headers["Accept"] = "application/javascript"
    patch(:update, { workspace_value: { field_value: "new value",
                                        name_id: @name.id,
                                        name_node_link_id: @name_node_link_id,
                                        value_label: "not important",
                                        type_uri_id_part: "accepted" } },
          username: "fred",
          user_full_name: "Fred Jones",
          groups: %w(edit treebuilder),
          workspace: @workspace)
    assert_response :success
  end
end
