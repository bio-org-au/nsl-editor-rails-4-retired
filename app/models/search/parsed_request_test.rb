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
class Search::ParsedRequestTest

  def initialize
    puts 'test'
    run_tests
  end

  def run_tests
    @tests_run = 0
    @assertions_count = 0
    @errors_count = 0
    explicit_name_test
    #implicit_name_test
    simple_ref_test
    simple_name_with_instances_test 
    author_search_by_query_target
    author_search_by_query_target_with_limit
    author_search_by_query_target_with_limit_mixed_case
    reference_with_instances_test 
    puts "tests: #{@tests_run}; assertions: #{@assertions_count}; errors: #{@errors_count}"
  rescue => e
    puts "Exception: #{e.to_s}"
  end

  def explicit_name_test
    @tests_run += 1
    pq = Search::ParsedRequest.new({"query_string"=>"Angophora Costata*", "query_target"=>"Names", "query_submit"=>"Search"})
    assert(pq.target_table == 'name','Target table should be "name".')
    assert(pq.defined_query == false,'explicit_name_test: should not be a defined query')
  end

  def implicit_name_test
    @tests_run += 1
    pq = Search::ParsedRequest.new({"query_string"=>"Angophora Costata*", "query_target"=>"", "query_submit"=>"Search"})
    assert(pq.target_table == 'name','Target table should be "name".')
    assert(pq.defined_query == false,'implicit_name_test: should not be a defined query')
  end

  def simple_ref_test 
    @tests_run += 1
    pq = Search::ParsedRequest.new({"query_string"=>"Angophora Costata*", "query_target"=>"References", "query_submit"=>"Search"})
    assert(pq.target_table == 'reference','Target table should be "reference".')
    assert(pq.defined_query == false,'simple_ref_test: should not be a defined query')
  end

  def author_search_by_query_target
    @tests_run += 1
    pq = Search::ParsedRequest.new({"query_string"=>"bent*", "query_target"=>"Authors", "query_submit"=>"Search"})
    assert(pq.defined_query == false,'author_search_by_query_target: should not be a defined query')
    assert(pq.target_table == 'author','Target table should be "author".')
  end

  def author_search_by_query_target_with_limit
    @tests_run += 1
    the_limit = 2
    pq = Search::ParsedRequest.new({"query_string"=>"bent* limit:#{the_limit}", "query_target"=>"Authors", "query_submit"=>"Search"})
    assert(pq.defined_query == false,'author_search_by_query_target_with_limit: should not be a defined query')
    assert(pq.target_table == 'author','Target table should be "author".')
    assert(pq.limit == the_limit,"Limit should be '#{the_limit}' not #{pq.limit}.")
  end

  def author_search_by_query_target_with_limit_mixed_case
    @tests_run += 1
    the_limit = 2
    pq = Search::ParsedRequest.new({"query_string"=>"bent* lIMit:#{the_limit}", "query_target"=>"Authors", "query_submit"=>"Search"})
    assert(pq.defined_query == false,'author_search_by_query_target_with_limit: should not be a defined query')
    assert(pq.target_table == 'author','Target table should be "author".')
    assert(pq.limit == the_limit,"Limit should be '#{the_limit}' not #{pq.limit}.")
  end

  def reference_with_instances_test 
    @tests_run += 1
    pq = Search::ParsedRequest.new({"query_string"=>"*", "query_target"=>"References with instances", "query_submit"=>"Search"})
    assert(pq.defined_query == true,'References with instances: should be a defined query')
    assert(pq.target_table == 'reference','Target table should be "reference".')
  end

  def assert(condition,error_message = 'No error message')
    @assertions_count += 1
    if condition == true
      puts '.'
    else
      puts "Error: #{error_message}"
      @errors_count += 1
    end
  end

end
