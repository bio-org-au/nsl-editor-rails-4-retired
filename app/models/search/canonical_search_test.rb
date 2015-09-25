#   encoding: utf-8
#
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
#
# Use during development for fast testing.
class Search::CanonicalSearchTest

  def run
    cs = call_with_string("acacia dealbata*")
    assert('Implicit list search', cs.list,'Should be a list')
    assert('Implicit list search so not a count required', !cs.count,'Should be a list')
    cs = call_with_string("count acacia dealbata*")
    assert('Explicit count search', cs.count,'Should be a count')
    assert('Explicit count search so no list', !cs.list,'Should be no list')
    #cs = Search::CanonicalSearch.new({"utf8"=>"✓", "search_from"=>"string", "query_string"=>"list acacia dealbata*"})
    cs = call_with_string("list acacia dealbata*")
    assert('Explicit list search', cs.list,'Should be a list')
    assert('Explicit list search so no count', !cs.count,'Should be no count')
  end

  def call_with_string(string)
    cs = Search::CanonicalSearch.new({"utf8"=>"✓", "search_from"=>"string", "query_string"=>string})
  end


  def assert(description,result,message)
    if result == true
      puts "Pass - #{description}"
    else
      puts "Fail - #{description} - #{message}"
    end
  end

end




