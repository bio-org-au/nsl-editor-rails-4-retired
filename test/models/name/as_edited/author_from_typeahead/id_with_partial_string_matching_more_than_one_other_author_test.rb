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
class NameAsEditedAuthorIdWithPartialStringMatchingMatchingMoreThanOneOtherAuthor < ActiveSupport::TestCase
  test "id with partial string matching more than one other author" do
    author_1 = authors(:dummy_author_1)
    author_2 = authors(:dummy_author_2)
    assert_raise(RuntimeError, "Should raise error because partial string does not identify just one author") do
      result = Name::AsEdited.author_from_typeahead(author_1.id.to_s, author_2.name.chop, "Some Author Field")
    end
  end
end
