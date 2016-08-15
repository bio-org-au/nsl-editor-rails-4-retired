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
load "models/search/users.rb"

# Single instance model test.
class NameUsagesOrderByReferenceYear < ActiveSupport::TestCase
  test "instance search name usages for casuarina inophloia order" do
    name = names(:casuarina_inophloia)
    first_ref = references(:australasian_chemist_and_druggist)
    second_ref = references(:mueller_1882_section)
    third_ref = references(:bailey_catalogue_qld_plants)
    params =  ActiveSupport::HashWithIndifferentAccess.new(
      query_string: "id:#{name.id} show-instances:",
      query_target: "Name",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    assert_equal search.executed_query.results.class,
                 Array, "Results should be an Array"
    assert_equal 4, search.executed_query.results.size, "One record expected."
    assert_equal name.id,
                 search.executed_query.results[1].name_id, "Name not first"
    # search.results.each {|r| puts "#{r.try('reference').try('year')}"}
    assert_equal first_ref.id,
                 search.executed_query.results[1].reference_id,
                 "Ref 1
                 wrong: #{search.executed_query.results[2].reference.year}"
    assert_equal second_ref.id,
                 search.executed_query.results[2].reference_id,
                 "Second reference wrong"
    assert_equal third_ref.id,
                 search.executed_query.results[3].reference_id,
                 "Third reference wrong"
  end
end
