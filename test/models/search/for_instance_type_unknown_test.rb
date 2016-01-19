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
class ForInstanceTypeUnknown < ActiveSupport::TestCase
  # Search model run_search for Instance for : "id: 86355" in "name-instances",
  # up to 1000000000 record(s)
  # Search model run_search for Instance for : "[unknown]" in "instance-type",
  # up to 100 record(s) (pid:93252)
  # @search = Search.new(params[:query],
  # params[:query_on],
  # params[:query_limit],
  # params[:query_common_and_cultivar]||'f',
  # params[:query_sort],params[:query_field])
  test "search for instance type of unknown using the query alone" do
    search = Search::Base
             .new(ActiveSupport::HashWithIndifferentAccess
             .new(query_string: "type: [unknown]",
                  query_target: "instance",
                  current_user: build_edit_user))
    assert_equal search.class, Search::Base, "Results should be a Search."
    assert_equal search.executed_query.results.class,
                 Instance::ActiveRecord_Relation,
                 "Results should be an Instance::ActiveRecord_Relation."
    assert_equal 1,
                 search.executed_query.results.size,
                 "Expected 1 result for instance-type search for [unknown]."
  end
end
