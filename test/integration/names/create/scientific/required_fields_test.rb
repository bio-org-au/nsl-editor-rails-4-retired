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
class RequiredFieldsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "create scientific name required fields" do
    visit_home_page
    fill_in "search-field", with: "for required fields"
    load_new_scientific_name_form
    assert(page.has_selector?('#name_name_type_id[required]'),
           "Name type should be a required field.")
    assert(page.has_selector?('#name_name_rank_id[required]'),
           "Name rank should be a required field.")
    assert(page.has_selector?('#name_name_status_id[required]'),
           "Name status should be a required field.")
    assert(page.has_selector?('#name_name_element[required]'),
           "Name element should be a required field.")
    assert(page.has_selector?('#name-parent-typeahead[required]'),
           "Name parent should be a required field.")
    assert(page.has_selector?('#ex-base-author-by-abbrev'),
           "Name ex-base author should be a field.")
    assert(page.has_no_selector?('#ex-base-author-by-abbrev[required]'),
           "Name ex-base author should not be a required field.")
    assert(page.has_selector?('#base-author-by-abbrev'),
           "Name base author should be a field.")
    assert(page.has_no_selector?('#base-author-by-abbrev[required]'),
           "Name base author should not be a required field.")
    assert(page.has_selector?('#ex-author-by-abbrev'),
           "Name ex author should be a field.")
    assert(page.has_no_selector?('#ex-author-by-abbrev[required]'),
           "Name ex author should not be a required field.")
    assert(page.has_selector?('#author-by-abbrev'),
           "Name author should be a field.")
    assert(page.has_no_selector?('#author-by-abbrev[required]'),
           "Name author should not be a required field.")
    assert(page.has_selector?('#sanctioning-author-by-abbrev'),
           "Name sanctioning author should be a field.")
    assert(page.has_no_selector?('#sanctioning-author-by-abbrev[required]'),
           "Name sanctioning0author should not be a required field.")
  end
end
