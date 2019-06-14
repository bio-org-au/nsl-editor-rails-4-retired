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

# Single integration test.
class NoDeleteButtonIfBaseAuthorOfName < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "author has no delete button if base author of name" do
    visit_home_page
    standard_page_assertions
    select "Author", from: "query-on"
    fill_in "search-field",
            with: "id: #{authors(:has_base_authored_one_name_that_is_all).id}"
    click_button "Search"
    tiny_sleep
    search_result_must_include_content("Has Base Authored One Name That Is All")
    click_link("Edit")
    big_sleep
    search_result_details_must_include_button("Save")
    search_result_details_must_not_include_link("Delete...")
  end
end
