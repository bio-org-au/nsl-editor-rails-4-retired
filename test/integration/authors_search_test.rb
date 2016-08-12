#   encoding: utf-8

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

# Test authors search.
class AuthorsSearchTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  # "bentham"
  test "author simple search for bentham" do
    sign_in
    select "Authors", from: "query-on"
    fill_in "search-field", with: "bentham"
    click_on "Search"
    standard_page_assertions
    assert page.has_content?("bentham"),
           "Search result for author 'bentham' not found."
  end

  # "bentham cr-b:4"
  test "author advanced search with text and created before criterion" do
    visit_home_page
    standard_page_assertions
    select "Authors", from: "query-on"
    fill_in "search-field", with: "bentham cr-b:4"
    click_on "Search"

    sleep(2)
    search_result_summary_must_include_content("0 records",
                                               'Incorrect summary for simple
                                               name search on "acacia" -
                                               missing: 0 records.')
    search_result_summary_must_include_content(
      'Author search: "bentham cr-b:4"',
      'Bad summary for author search on "bentham cr-b:4" -
      missing: Author search: "bentham cr-b:4".'
    )
  end

  # "bentham cr-b:"
  test "better author advanced search w text and empty created b4 criterion" do
    sign_in
    standard_page_assertions
    select "Authors", from: "query-on"
    fill_in "search-field", with: "bentham cr-b:"
    click_on "Search"
    sleep(2)
    search_result_summary_must_include_content(
      "0 records",
      'Bad summary for simple name search on "acacia" - missing: 0 records.'
    )
    search_result_summary_must_include_content(
      '0 records Author search: "bentham cr-b:"(Ignored criteria: cr-b)',
      "Incorrect summary for author search with empty criterion."
    )
  end
end
