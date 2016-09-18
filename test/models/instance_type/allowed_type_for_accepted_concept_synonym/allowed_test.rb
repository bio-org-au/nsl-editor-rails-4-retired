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

# Instance type category test.
class InstTypeAllowedType4AcceptConSynAllowedTest < ActiveSupport::TestCase
  test "doubtful misapplied is allowed" do
    record = instance_types(:doubtful_misapplied)
    assert record.allowed_type_for_accepted_concept_synonym?,
           "This type should be allowed."
  end

  test "doubtful pro parte misapplied is allowed" do
    record = instance_types(:doubtful_pro_parte_misapplied)
    assert record.allowed_type_for_accepted_concept_synonym?,
           "This type should be allowed."
  end

  test "misapplied is allowed" do
    record = instance_types(:misapplied)
    assert record.allowed_type_for_accepted_concept_synonym?,
           "This type should be allowed."
  end

  test "pro parte misapplied is allowed" do
    record = instance_types(:pro_parte_misapplied)
    assert record.allowed_type_for_accepted_concept_synonym?,
           "This type should be allowed."
  end

  test "pro parte taxonomic synonym is allowed" do
    record = instance_types(:pro_parte_taxonomic_synonym)
    assert record.allowed_type_for_accepted_concept_synonym?,
           "This type should be allowed."
  end
end
