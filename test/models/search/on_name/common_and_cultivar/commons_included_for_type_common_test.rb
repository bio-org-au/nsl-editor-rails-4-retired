#   encoding: utf-8

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
load "test/models/search/users.rb"

# Single Search model test.
class SearchOnNameNameCommonsIncluded4TypeCommonTest < ActiveSupport::TestCase
  test "search on name name commons included for type common" do
    params =
      ActiveSupport::HashWithIndifferentAccess.new(
        query_target: "name",
        query_string: "name: argyle apple type: common",
        current_user: build_edit_user)
    search = Search::Base.new(params)
    assert_equal search.executed_query.results.class,
                 Name::ActiveRecord_Relation,
                 "Results should be a Name::ActiveRecord_Relation."
    assert_equal 1, search.executed_query.results.size,
                 "Expected common name to be included for type common"
  end
end