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

class OrderByPage < ActiveSupport::TestCase

  test "approximates numeric sorting" do
    name = names(:angophora_costata)
    results = Instance.joins(:name).limit(400).ordered_by_page
    #results.each_with_index {|i,ndx| puts "#{ndx}: #{i.page} - #{i.name.full_name}"};
    assert results.first.page == 'xx 1', "Wrong order at first value: #{results[0].page}."
    assert results.second.page == '2', "Wrong order at second value: #{results[1].page}."
    assert results.third.page == '3', "Wrong order at third value: #{results[2].page}."
    assert results[3].page == 'xx 15', "Wrong order at fourth value: #{results[3].page}."
    assert results[4].page == '19-20', "Wrong order at fifth value: #{results[4].page}."
    assert results[5].page.match(/\Axx,20,/), "Wrong order at sixth value: #{results[5].page}."
    assert results[9].page == '40', "Wrong order at tenth value: #{results[9].page}."
    assert results[10].page == '41', "Wrong order at eleventh value: #{results[10].page}."
    assert results[13].page == '75, t. 101', "Wrong order at the fourteenth value: #{results[13].page}."
    assert results[14].page == '75, t. 102', "Wrong order at the fifteenth value: #{results[14].page}."
    assert results[16].page == 'xx 200,300', "Wrong order at the seventeenth value: #{results[16].page}."
  end
 
end


