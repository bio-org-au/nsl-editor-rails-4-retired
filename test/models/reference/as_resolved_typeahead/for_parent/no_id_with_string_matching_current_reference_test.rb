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

# Reference model parent from typeahead test.
class RefARTA4PNoIdWStrMatchingCurrentReferenceTest < ActiveSupport::TestCase
  test "no id with string matching current reference" do
    skip
    # reference_1 = references(:has_a_matching_citation_1)
    # assert Reference.where(citation: reference_1.citation).size == 2,
    # "Should be two References with the same citation string."
    # assert_raise(RuntimeError, "Should fail - invalid reference string.") do
    #   Reference::AsEdited.parent_from_typeahead('',reference_1.citation)
    # end
  end
end
