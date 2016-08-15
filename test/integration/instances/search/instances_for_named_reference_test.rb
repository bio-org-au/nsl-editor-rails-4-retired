#   encoding: utf-8
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
class InstancesForNamedReference < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "ref instances search for string" do
    visit_home_page
    standard_page_assertions
    select "Instance", from: "query-on"
    select "for reference", from: "query-field"
    fill_in "search-field", with: "journal of botany"
    click_button "Search"
    search_result_must_include_content("Journal of Botany")
    search_result_must_include_content("Angophora costata")
    search_result_must_include_content("Metrosideros costata")
    search_result_must_include_content("Rusty Gum")
  end
end
