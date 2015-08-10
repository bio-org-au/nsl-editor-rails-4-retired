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
require 'test_helper'

class WouldChangeTest < ActiveSupport::TestCase

  test "handles empty params" do
    instance = instances(:britten_created_angophora_costata)
    assert_not instance.would_change?(nil), "No params supplied so should not be a change."
  end
 
  test "ignores unchanged name id" do
    instance = instances(:britten_created_angophora_costata)
    assert_not instance.would_change?({"name_id"=>instance.name_id.to_s}), "Name id is the same so change should not be detected."
  end
 
  test "detects changed name id" do
    instance = instances(:britten_created_angophora_costata)
    assert instance.would_change?({"name_id"=>(instance.name_id + 1).to_s}), "Name id has changed and that should be detected."
  end
 
end


