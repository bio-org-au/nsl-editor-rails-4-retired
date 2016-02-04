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
class AuthAsEdNoDupeOfIdWValStrWTrailingWhite < ActiveSupport::TestCase
  test "no id with valid string" do
    current_author_id = 1
    author = authors(:chaplin)
    result = Author::AsEdited.duplicate_of_from_typeahead(
      "", author.name + " ", current_author_id)
    assert_equal author.id, result, "Should get a matching id for the author"
  end
end
