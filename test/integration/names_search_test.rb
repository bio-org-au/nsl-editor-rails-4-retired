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

# Test search name.
class NamesSearchTest < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  test "search page" do
    visit_home_page
    standard_page_assertions
  end

  test "names simple search" do
    visit_home_page
    standard_page_assertions
    select "Names", from: "query-on"
    fill_in "search-field", with: "acacia"
    click_button "Search"
    sleep(1.1)
    search_result_summary_must_include_content(
      "1 record",
      "Bad summary for simple name search on 'acacia' - missing: 1 record."
    )
    search_result_must_include_content(
      "Acacia",
      "Bad result for simple name search on 'acacia' - missing: 'Acacia'."
    )
    search_result_summary_must_include_content(
      "excluding common and cultivar",
      "Bad summary for simple name search - missing: excl common and cultivar."
    )
  end

  # "acacia a:bentham"
  test "names advanced search with author specifier" do
    visit "/search?query=acacia+a%3Abentham"
    standard_page_assertions
    assert page.has_content?("Acacia", minimum: 1),
           "Search result for name 'Acacia' not found."
  end

  # "distans a:bentham cr-b:2014"
  test "names advanced search with created-after specifier" do
    visit "/search?query=distens+a%3Abentham+cr-a%3A2000"
    standard_page_assertions
    assert page.has_content?("distens", minimum: 1),
           "Search result for name 'distens' not found."
  end

  # "acacia a:bentham cr-b:20000"
  test "names advanced search with created-before specifier" do
    visit "/search?query=acacia+a%3Abentham+cr-b%3A20000"
    standard_page_assertions
  end

  # "acacia a:bentham cr-b:"
  test "names advanced search with empty created-before specifier" do
    visit "/search?query=acacia+a%3Abentham+cr-b%3A"
    standard_page_assertions
  end

  test "names simple search excluding common and cultivar" do
    query1 =  "/search?query_on=name&query_field=&query=argyle+apple&"
    query2 = "query_limit=10&query_common_and_cultivar=f"
    visit "#{query1}#{query2}"
    standard_page_assertions
    assert page.has_content?("0 records", minimum: 1),
           "Search result for name
           'argyle apple, excluding common and cultivar' not correct."
    assert page.has_content?("argyle apple", minimum: 1),
           "Search for 'argyle apple, excluding common and cultivar' wrong."
  end

  test "names simple search including common and cultivar" do
    visit "/search?query=argyle+apple+a%3Abentham&query_common_and_cultivar=t"
    standard_page_assertions
    assert page.has_content?("1 record", minimum: 1),
           "Search res 4 name 'argyle apple, incl common and cultivar' wrong"
  end

  test "query on name is available" do
    visit_home_page
    select "Name", from: "query-on"
    assert find("#query-on").value == "name",
           "Name query should be available and selected."
  end

  test "query on reference is available" do
    visit_home_page
    select "Reference", from: "query-on"
    assert find("#query-on").value == "reference",
           "Reference query should be available and selected."
  end

  test "query on instance is available" do
    visit_home_page
    select "Instance", from: "query-on"
    assert find("#query-on").value == "instance",
           "Instance query should be available and selected."
  end

  test "name search option author" do
    visit_home_page
    select "Name", from: "query-on"
    select "with author", from: "query-field"
    assert find("#query-field").value == "a",
           "Author query should be available and selected."
  end

  test "name search with base author" do
    visit_home_page
    select "Name", from: "query-on"
    select "with base author", from: "query-field"
    assert find("#query-field").value == "ba",
           "with base author query should be available and selected."
  end

  test "name search option with ex author" do
    visit_home_page
    select "Name", from: "query-on"
    select "with ex author", from: "query-field"
    assert find("#query-field").value == "ea",
           "with ex author query should be available and selected."
  end

  test "name search option with ex base author" do
    visit_home_page
    select "Name", from: "query-on"
    select "with ex base author", from: "query-field"
    assert find("#query-field").value == "eba",
           "ex base author query should be available and selected."
  end

  test "name search option with full name" do
    visit_home_page
    select "Name", from: "query-on"
    select "with full name", from: "query-field"
    assert find("#query-field").value == "fn",
           "with full name query should be available and selected."
  end

  test "name search option with simple name" do
    visit_home_page
    select "Name", from: "query-on"
    select "with simple name", from: "query-field"
    assert find("#query-field").value == "sn",
           "with simple name query should be available and selected."
  end

  test "name search option with name element" do
    visit_home_page
    select "Name", from: "query-on"
    select "with name element", from: "query-field"
    assert find("#query-field").value == "ne",
           "with name element query should be available and selected."
  end

  test "name search option with name type" do
    visit_home_page
    select "Name", from: "query-on"
    select "with name type", from: "query-field"
    assert find("#query-field").value == "nt",
           "with name type query should be available and selected."
  end

  test "name search option with not name type" do
    visit_home_page
    select "Name", from: "query-on"
    select "with not name type", from: "query-field"
    assert find("#query-field").value == "not-nt",
           "with not name type query should be available and selected."
  end

  test "name search option with name rank" do
    visit_home_page
    select "Name", from: "query-on"
    select "with name rank", from: "query-field"
    assert find("#query-field").value == "nr",
           "with name rank query should be available and selected."
  end

  test "name search option with sanctioning auth" do
    visit_home_page
    select "Name", from: "query-on"
    select "with sanctioning auth", from: "query-field"
    assert find("#query-field").value == "sa",
           "with sanctioning auth query should be available and selected."
  end

  test "name search option with id" do
    visit_home_page
    select "Name", from: "query-on"
    select "with id", from: "query-field"
    assert find("#query-field").value == "id",
           "with id query should be available and selected."
  end

  test "name search option duplicate of" do
    visit_home_page
    select "Name", from: "query-on"
    select "duplicate of", from: "query-field"
    assert find("#query-field").value == "duplicate-of",
           "duplicate of query should be available and selected."
  end

  test "name search option with ids" do
    visit_home_page
    select "Name", from: "query-on"
    select "with ids", from: "query-field"
    assert find("#query-field").value == "ids",
           "with ids query should be available and selected."
  end

  test "name search option for reference" do
    visit_home_page
    select "Name", from: "query-on"
    select "for reference", from: "query-field"
    assert find("#query-field").value == "for-reference",
           "for reference query should be available and selected."
  end

  test "name search option hours since created" do
    visit_home_page
    select "Name", from: "query-on"
    select "hours since created", from: "query-field"
    assert find("#query-field").value == "hours-since-created",
           "hours since created query should be available and selected."
  end

  test "name search option hours since updated" do
    visit_home_page
    select "Name", from: "query-on"
    select "hours since updated", from: "query-field"
    assert find("#query-field").value == "hours-since-updated",
           "hours since updated query should be available and selected."
  end

  test "name search option created since" do
    visit_home_page
    select "Name", from: "query-on"
    select "created since", from: "query-field"
    assert find("#query-field").value == "cr-a",
           "created since query should be available and selected."
  end

  test "name search option created before" do
    visit_home_page
    select "Name", from: "query-on"
    select "created before", from: "query-field"
    assert find("#query-field").value == "cr-b",
           "created before query should be available and selected."
  end

  test "name search option updated since" do
    visit_home_page
    select "Name", from: "query-on"
    select "updated since", from: "query-field"
    assert find("#query-field").value == "upd-a",
           "updated since query should be available and selected."
  end

  test "name search option updated before" do
    visit_home_page
    select "Name", from: "query-on"
    select "updated before", from: "query-field"
    assert find("#query-field").value == "upd-b",
           "updated before query should be available and selected."
  end

  test "name search option name rank" do
    visit_home_page
    select "Name", from: "query-on"
    select "with name rank", from: "query-field"
    assert find("#query-field").value == "nr",
           "Name rank query should be available and selected."
  end

  test "name search option name status" do
    visit_home_page
    select "Name", from: "query-on"
    select "with name status", from: "query-field"
    assert find("#query-field").value == "ns",
           "Name status query should be available and selected."
  end

  def search_result_must_include(link_text, msg)
    assert find("div#search-result-container").has_link?(link_text), msg
  end

  def search_result_must_not_include(link_text, msg)
    assert_not find("div#search-result-container").has_link?(link_text), msg
  end
end
