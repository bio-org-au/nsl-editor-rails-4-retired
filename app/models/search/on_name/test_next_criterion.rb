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
class Search::OnName::TestNextCriterion

  def initialize
    run
  end

  def run
    @passed = 0
    @failed = 0
    test_simple_search
    test_simple_search_with_criterion_following
    test_field_with_value
    summary
  end

  def summary
    puts "Summary: passed: #{@passed}; failed: #{@failed}"
  end

  def next_criterion(string)
    son = Search::OnName::NextCriterion.new(string)
  end

  def test_simple_search
    simple_name = "acacia dealbata"
    nc = next_criterion(simple_name)
    field,value,remaining = nc.get
    assert('Simple name search', field.blank?, "Field should be blank but is #{field}")
    assert('Simple name search', !!value.match(/#{simple_name}/),"Value should match #{simple_name} but is #{value}")
    assert('Simple name search - remaining blank', remaining.blank?,"Should be blank but is #{remaining}")
  end


  def test_simple_search_with_criterion_following
    simple_name = "acacia dealbata"
    extra_field = "xyz: blah"
    simple_name_with_extra_field = "#{simple_name} #{extra_field}"
    nc = next_criterion(simple_name_with_extra_field)
    field,value,remaining = nc.get
    assert('Simple name search', field.blank?, "Field should be blank but is #{field}")
    assert('Simple name search', !!value.match(/#{simple_name}/),"Value should match #{simple_name} but is #{value}")
    assert('Simple name search - remainder', !!remaining.match(/#{extra_field}/),"Should be #{extra_field} but is #{remaining}")
  end

  def test_field_with_value
    input_field = "name-rank:"
    input_value = "genus"
    input_field_with_value = "#{input_field} #{input_value}"
    nc = next_criterion(input_field_with_value)
    field,value,remaining = nc.get
    assert('Field with value search - field', !!field.match(/#{input_field}/), "Field should be #{input_field} not #{field}")
    assert('Field with value search - value', !!value.match(/#{input_value}/),"Value should match #{input_value} but is #{value}")
    assert('Field with value search - remainder', remaining.blank?,"Should be blank but is #{remaining}")
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



