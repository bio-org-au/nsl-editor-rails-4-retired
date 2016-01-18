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
load "models/search/users.rb"

# Single Search model test.
class SearchNameInstancesTest < ActiveSupport::TestCase
  # Search model run_search for Instance for : "id: 86355" in "name-instances", up to 1000000000 record(s)
  test "search" do
    name = names(:the_regnum)
    search = Search::Base.new(ActiveSupport::HashWithIndifferentAccess.new(query_string: "#{name.id}", query_target: "instances-for-name-id", current_user: build_edit_user))
    assert_equal search.class, Search::Base, "Results should be a Search."
    assert_equal search.executed_query.results.class, Array, "Results should be an Array."
    assert_equal 2, search.executed_query.results.size, "Expected 2 search results for name-instances search on the Plantae Haeckel."
  end
end
