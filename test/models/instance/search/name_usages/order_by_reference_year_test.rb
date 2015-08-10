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

class NameUsagesOrderByReferenceYear < ActiveSupport::TestCase

  test "instance search name usages for casuarina inophloia order" do
    name = names(:casuarina_inophloia)
    first_ref = references(:australasian_chemist_and_druggist)
    second_ref = references(:mueller_1882_section)
    third_ref = references(:bailey_catalogue_qld_plants)
    search = Search.new("#{name.id}",'Instance','100','f','','name-usages')
    assert_equal search.results.class, Array, "Results should be an Array."
    assert_equal 4, search.results.size, "One record expected."
    assert_equal name.id, search.results[1].name_id
    assert_equal first_ref.id, search.results[1].reference_id
    assert_equal second_ref.id, search.results[2].reference_id
    assert_equal third_ref.id, search.results[3].reference_id
  end

end
  
