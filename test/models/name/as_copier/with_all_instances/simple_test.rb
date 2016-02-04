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

# Single name model test.
class NameAsCopierWithAllInstancesSimpleTest < ActiveSupport::TestCase
  test "copy name with all instances" do
    before = Name.count
    master_name = Name::AsCopier.find(names(:a_genus_with_two_instances).id)
    dummy_name_element = "xyz"
    dummy_username = "fred"
    master_instances_before = master_name.instances.size
    copied_name = master_name.copy_with_all_instances(
      dummy_name_element,
      dummy_username)
    after = Name.count
    copied_instances_after = copied_name.instances.size
    assert_equal before + 1, after, "There should be one extra name."
    assert_equal master_instances_before,
                 copied_instances_after,
                 "New name should have instances."
    assert_match dummy_name_element, copied_name.name_element
    assert_equal dummy_username, copied_name.created_by
    assert_equal dummy_username, copied_name.updated_by
  end
end
