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
class InstanceSearchCiteInstanceIdNoSuchInstanceTest < ActiveSupport::TestCase
  # New search for "42993" on instance up to 100
  # with field: reverse-of-cites-id-query
  test "instance search on cite instance id" do
    skip # On switch to new_search, not sure if this is still required.
    # Can't tell what the query_target should be.
    # search = Search::Base.new({query_string:"1",
    # query_target:'Instance',wat:'reverse-of-cites-id-query'})
    # assert_equal search.results.class, Array, "Results should be an Array"
    # assert search.results.size == 0, "Empty Array expected."
  end
end
