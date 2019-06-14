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
class RequiredFieldsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "reference required fields" do
    visit_home_page
    fill_in "search-field", with: "reference check required fields for create"
    select_from_menu(%w(New Reference))
    search_result_must_include_content("New reference")
    search_result_details_must_include_content("New Reference")
    assert(page.has_selector?("#reference_ref_type_id[required]"),
           "Reference type should be a required field.")
    assert(page.has_no_selector?("#reference-parent-typeahead[required]"),
           "reference-parent-typeahead should not be a required field.")
    assert(page.has_selector?("#reference_title[required]"),
           "Reference title should be a required field.")
    assert(page.has_selector?("#reference-author-typeahead[required]"),
           "Reference author (typeahead) should be a required field.")
    assert(page.has_selector?("#reference_ref_author_role_id[required]"),
           "Reference author role should be a required field.")
    assert(page.has_no_selector?("#reference_pages[required]"),
           "reference pages should not be a required field.")
    assert(page.has_no_selector?("#reference_edition[required]"),
           "reference edition should not be a required field.")
    assert(page.has_no_selector?("#reference_volume[required]"),
           "reference volume should not be a required field.")
    assert(page.has_no_selector?("#reference_year[required]"),
           "reference year should not be a required field.")
    assert(page.has_no_selector?("#reference_publication_date[required]"),
           "reference publication date should not be a required field.")
    assert(page.has_no_selector?("#reference_notes[required]"),
           "reference notes should not be a required field.")
  end
end
