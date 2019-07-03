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

# Single Reference model test.
class PagesValidWith255CharsTest < ActiveSupport::TestCase
  test "pages valid with 255 chars" do
    reference = references(:simple)
    assert reference.valid?, "Should start out valid"
    reference.pages = "x" * 255
    assert reference.valid?, "Should be valid with 255 chars"
    reference.pages = "y" * 256
    assert_not reference.valid?, "Should not be valid with 256 chars"
  end
end
