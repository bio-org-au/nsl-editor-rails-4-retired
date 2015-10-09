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
require 'test_helper'

class SearchParseQueryList20Test < ActiveSupport::TestCase

  test "search parse query list 20" do
    query_string = 'list 20'
    params = {'query_string'=> query_string}
    parsed_query = Search::ParsedQuery.new(params)
    assert parsed_query.list, "This should be parsed as a list query."
    assert !parsed_query.count, "This should not be parsed as a count query."
    assert_match /\Aname\z/, parsed_query.target_table,"This should be parsed as a query on the name table."
    assert parsed_query.limited, "This should be parsed as a query with a limit."
    assert_equal parsed_query.limit, 20, "This should be parsed as a query with a limit of 20."
    assert !parsed_query.common_and_cultivar, "This should be parsed as a query excluding common and cultivars."
    assert parsed_query.where_arguments.blank?, "This should be parsed as a query with no where arguments."
  end

end
