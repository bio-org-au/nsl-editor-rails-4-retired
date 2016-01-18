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

# Single author model test.
class AuthorAsEditedDuplicateOfIdWithStringMatching2Names < ActiveSupport::TestCase
  test "id with string matching 2 authors" do
    current_author_id = 1
    author_1 = authors(:has_matching_name_1)
    author_2 = authors(:has_matching_name_2)
    assert author_1.name.match(author_2.name), "Should be two authors with the same name."
    result = Author::AsEdited.duplicate_of_from_typeahead(author_2.id.to_s, author_2.name, current_author_id)
    assert_equal author_2.id, result, "Should get a match for the correct id"
  end
end
