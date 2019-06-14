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

# Single name model test.
class NameARTAh4Parent2WValStrWithTrailWhitespce < ActiveSupport::TestCase
  test "no id with valid string with trailing whitespace" do
    name = names(:the_regnum)
    result = Name::AsResolvedTypeahead::ForParent.new("",
                                                      name.full_name + "  ",
                                                      "second_parent")
    assert_equal name.id, result.value, "Should get a matching id for the name"
  end
end
