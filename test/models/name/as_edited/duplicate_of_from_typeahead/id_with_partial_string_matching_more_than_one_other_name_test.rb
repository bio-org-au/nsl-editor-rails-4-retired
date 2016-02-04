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
class NameAsEdDupeOfIdWPartStrMatchMoreThan1OtherName < ActiveSupport::TestCase
  test "duplicate of id with partial string matching more than 1 other name" do
    name_1 = names(:name_matches_another_1)
    name_2 = names(:name_matches_another_1)
    assert_raise(RuntimeError,
                 "Should fail - string does not identify just one name") do
      Name::AsEdited.duplicate_of_from_typeahead(
        name_1.id.to_s,
        name_2.full_name[0])
    end
  end
end
