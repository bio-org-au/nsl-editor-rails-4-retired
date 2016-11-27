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
class InstTypeAllowedType4AcceptConSynNotAllowedTest < ActiveSupport::TestCase
  test "the rest are not allowed" do
    InstanceType.all.sort_by(&:name).each do |record|
      next if record.misapplied? ||
              record.name.match(/\Apro parte taxonomic synonym\z/)
      assert_not record.allowed_type_for_accepted_concept_synonym?,
                 "Instance type #{record.name} should NOT be allowed."
    end
  end
end
