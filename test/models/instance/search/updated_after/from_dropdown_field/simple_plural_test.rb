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

class InstanceSearchUpdatedAfterFromDropdownSimplePluralTest < ActiveSupport::TestCase

  #New search for "42993" on instance up to 100 with field: upd-b
  test "instance search on updated after from dropdown field simple plural" do
    search = Search.new("2",'Instance','100','f','','upd-a')
    assert_equal search.results.class, Instance::ActiveRecord_Relation, "Results should be an Instance::ActiveRecord_Relation"
    assert search.results.size > 20, "Plenty of records expected."
    assert_match /Search for instances updated less than 2 days ago./, search.info.join
  end

end
