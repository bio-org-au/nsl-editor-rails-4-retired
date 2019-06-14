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

# Single instance model test.
class InstSearchReverseOfCitedByIdNoSuchInstanceTest < ActiveSupport::TestCase
  # New search for "42993" on instance up to 100
  # with field: reverse-of-cited-by-id-query
  test "instance search on reverse of cited by instance id" do
    skip # on switch to new search not sure what the target should be
    # search = Search::Base.new("1",'Instance','100',
    # 'f','','reverse-of-cited-by-id-query')
    # assert_equal search.results.class, Array, "Results should be an Array"
    # assert search.results.size == 0, "Empty Array expected."
  end
end
