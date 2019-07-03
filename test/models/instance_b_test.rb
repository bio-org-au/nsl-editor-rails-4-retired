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

# Instance tests.  Not yet split into single files.
class InstanceBTest < ActiveSupport::TestCase
  test "relationship synonymy instance cannot be cited by itself" do
    relationship_instance =
      instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert_not relationship_instance.cited_by_id == relationship_instance.id
    relationship_instance.cited_by_id = relationship_instance.id
    assert_not relationship_instance.valid?, "should not be valid"
  end

  test "relationship unpub cit instance cannot be cited by itself" do
    relationship_instance =
      instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    assert_not relationship_instance.cited_by_id == relationship_instance.id
    relationship_instance.cited_by_id = relationship_instance.id
    assert_not relationship_instance.valid?, "should not be valid"
  end

  test "relationship synonymy instance cannot cite itself" do
    relationship_instance =
      instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert_not relationship_instance.cites_id == relationship_instance.id
    relationship_instance.cites_id = relationship_instance.id
    assert_not relationship_instance.valid?, "should not be valid"
  end

  test "cannot remove cites id when updating an instance" do
    synonymy_instance =
      instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert_not synonymy_instance.name_id == names(:angophora_costata)
    synonymy_instance.cites_id = nil
    assert_not synonymy_instance.valid?, "should not be valid"
  end
end
