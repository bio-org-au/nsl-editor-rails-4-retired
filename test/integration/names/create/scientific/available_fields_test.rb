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

# Single integration test.
class AvailableFieldsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "create scientific name available fields" do
    visit_home_page
    fill_in "search-field", with: "test: scientific name available fields"
    load_new_scientific_name_form
    assert page.has_field?("name_name_type_id"), "Name type missing"
    assert page.has_field?("name_name_rank_id"), "Name rank missing"
    assert page.has_field?("name_name_status_id"), "Name status missing"
    assert page.has_field?("name_name_element"), "Name element missing"
    assert page.has_field?("name-parent-typeahead"),
           "Name parent typeahead field missing"
    assert page.has_field?("ex-base-author-by-abbrev"),
           "ex-base-author-by-abbrev missing"
    assert page.has_field?("base-author-by-abbrev"),
           "base-author-by-abbrev missing"
    assert page.has_field?("ex-author-by-abbrev"), "ex-author-by-abbrev missing"
    assert page.has_field?("author-by-abbrev"), "author-by-abbrev missing"
    assert page.has_field?("search-field"), "No search field."
    assert page.has_field?("sanctioning-author-by-abbrev"),
           "Sanctioning author field missing"
    assert page.has_field?("name_verbatim_rank"),
           "Name verbatim rank field missing"
  end
end
