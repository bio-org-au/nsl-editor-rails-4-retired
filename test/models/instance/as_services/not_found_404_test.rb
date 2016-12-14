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
require "models/instance/as_services/404_stub_helper"

# Single instance model test.
class InstanceDeleteServiceNotFound404Test < ActiveSupport::TestCase
  setup do
    # stub_it
    stub_request(:delete, "http://localhost:9090/nsl/services/instance/apni/404/api/delete?apiKey=test-api-key&reason=Edit")
      .with(headers: { "Accept" => "application/json", "Accept-Encoding" => "gzip, deflate", "Host" => "localhost:9090",
    "User-Agent" => /ruby/ })
      .to_return(status: 404, body: "", headers: {})
  end

  test "instance delete service not found 404" do
    assert_raise(RestClient::ResourceNotFound,
                 "Should raise runtime exception for not found") do
      # The test mock service determines response based on the id
      Instance::AsServices.delete(404)
    end
  end
end
