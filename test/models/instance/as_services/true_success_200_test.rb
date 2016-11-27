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
require "models/instance/as_services/success_stub_helper"

# Single instance model test.
class InstanceAsServicesTrueSuccess200Test < ActiveSupport::TestCase
  setup do
    stub_request(:delete, "http://localhost:9090/nsl/services/instance/apni/200/api/delete?apiKey=test-api-key&reason=Edit")
      .with(headers: { "Accept" => "application/json", "Accept-Encoding" => "gzip, deflate", "Host" => "localhost:9090", "User-Agent" => "rest-client/2.0.0 (darwin16.1.0 x86_64) ruby/2.3.0p0" })
      .to_return(status: 200, body: { "instance": { "class": "au.org.biodiversity.nsl.Instance", "_links": { "permalink": { "link": "http://localhost:8080/nsl/mapper/boa/instance/apni/819227", "preferred": true, "resources": 1 } }, "instanceType": "taxonomic synonym", "protologue": false, "citation": "Leach, G.J. (1986), A Revision of the Genus Angophora (Myrtaceae). Telopea 2(6)", "citationHtml": "Leach, G.J. (1986), A Revision of the Genus Angophora (Myrtaceae). Telopea 2(6)" }, "action": "delete", "ok": true }.to_json, headers: {})
  end

  test "instance delete service true success 200" do
    assert_nothing_raised("Should not raise exception if everything is ok") do
      # The test mock responds based on the id
      Instance::AsServices.delete(200)
    end
  end
end
