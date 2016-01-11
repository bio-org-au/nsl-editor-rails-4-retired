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

class ReferenceAsEditedDuplicateOfIdWithMatchingString < ActiveSupport::TestCase
  test "id with matching string" do
    reference = references(:journal_of_botany_british_and_foreign)
    result = Reference::AsEdited.duplicate_of_from_typeahead(reference.id, reference.citation)
    assert_equal reference.id, result, "The typeahead result should match the ID"
  end
end
