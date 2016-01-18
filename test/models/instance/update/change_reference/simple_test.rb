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

# Single instance model test.
class InstanceUpdateChangeReferenceSimpleTest < ActiveSupport::TestCase
  test "change reference simple" do
    instance = instances(:britten_created_angophora_costata)
    instance_back_door = InstanceBackDoor.find(instance.id)
    new_reference = references(:a_book)
    username = "ref-changer"
    assert instance_back_door.reference_id != new_reference.id, "Reference IDs should start out different."
    assert instance_back_door.updated_by != username, "Usernames should start out different."
    assert (instance.citations || []).size > 0, "Need citations for this test."
    instance.citations.each do |citation|
      assert citation.reference_id == instance.reference_id, "Should start out pointing to the same reference."
    end

    instance_back_door.change_reference({ "reference_id" => new_reference.id }, "ref-changer")

    assert instance_back_door.reference_id == new_reference.id, "Reference IDs should now be the same."
    assert instance_back_door.updated_by == username, "Usernames should now be the same."
    instance.citations.each do |citation|
      citation_back_door = InstanceBackDoor.find(citation.id)
      assert citation_back_door.reference_id == new_reference.id, "Dependent instance should now also point to the new reference."
      assert citation_back_door.updated_by == username, "Dependent instance should now also point to the new reference."
    end
  end
end
