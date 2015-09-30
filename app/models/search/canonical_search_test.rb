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
    @passed = 0
    @failed = 0
    test_implicit_list
    test_explicit_count
    test_explicit_list
    test_implicit_limit
    test_explicit_limit
    test_explicit_limit_for_a_count
    summary
  end

  def summary
    puts "Summary: passed: #{@passed}; failed: #{@failed}"
  end

  def test_implicit_list
    cs = call_with_string("acacia dealbata*")
    assert('Implicit list search', cs.list,'Should be a list')
    assert('Implicit list search so not a count required', !cs.count,'Should be a list')
  end

  def test_explicit_count
    cs = call_with_string("count acacia dealbata*")
    assert('Explicit count search', cs.count,'Should be a count')
    assert('Explicit count search so no list', !cs.list,'Should be no list')
  end

  def test_explicit_list
    cs = call_with_string("list acacia dealbata*")
    assert('Explicit list search', cs.list,'Should be a list')
    assert('Explicit list search so no count', !cs.count,'Should be no count')
  end

  def test_implicit_limit
    cs = call_with_string("acacia dealbata*")
    assert('Implicit limit search', cs.list_limit == 100,"Should be 100 not #{cs.list_limit}")
  end

  def test_explicit_limit
    cs = call_with_string("9 acacia dealbata*")
    assert('Implicit limit search', cs.list_limit == 9 ,"Should be 9 not #{cs.list_limit}")
  end

  def test_explicit_limit_for_a_count
    cs = call_with_string("count 9 acacia dealbata*")
    assert('Implicit limit search', cs.list_limit == 9 ,"Should be 9 not #{cs.list_limit}")
  end

  def call_with_string(string)
    cs = Search::CanonicalSearch.new({"utf8"=>"✓", "search_from"=>"string", "query_string"=>string})
  end


  def assert(description,result,message)
    if result == true
      @passed += 1
      puts "Pass - #{description}"
    else
      @failed += 1
      puts "Fail - #{description} - #{message}"
    end
  end

end




