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

class NameSearchOnNameWithEmbeddedQuotesTest < ActionController::TestCase
  tests SearchController

  #<tr id="search-result-76253122"
  test "name search on name with embedded quotes" do
    name = names(:boronia_lipstick)
    get(:index,{'query_on'=>'name','query'=>"*lipstick",'query_common_and_cultivar'=>'t','query_limit'=>'100'},{username: 'fred', user_full_name: 'Fred Jones', groups: []})
    assert_response :success
    assert_select "span#search-results-summary", /1 record /, "Should find 1 record"
    assert_select "tr#search-result-#{name.id}", true, "Should find the name."
  end

end



