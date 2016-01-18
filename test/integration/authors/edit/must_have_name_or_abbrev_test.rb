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
class MustHaveNameOrAbbrevTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "author must have name or abbrev" do
    visit_home_page
    select "Author", from: "query-on"
    fill_in "search-field", with: "Author that can be deleted"
    click_button "Search"
    big_sleep
    search_result_must_include_content("Author that can be deleted")
    click_link("Edit")
    big_sleep
    fill_in("author_name", with: "")
    fill_in("author_abbrev", with: "")
    save_edits
    big_sleep
    search_result_details_must_include_content("2 errors prohibited this author from being saved:")
    search_result_details_must_include_content("Name can't be blank if abbrev is blank.")
    search_result_details_must_include_content("Abbrev can't be blank if name is blank.")
  end
end
