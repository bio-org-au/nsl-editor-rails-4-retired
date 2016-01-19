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

  test "reference available fields" do
    visit_home_page
    fill_in "search-field", with: "reference check available fields for create"
    select_from_menu(%w(New Reference))
    search_result_must_include_content("New reference")
    search_result_details_must_include_content("New Reference")
    assert page.has_field?("reference_ref_type_id"),
           '#reference_ref_type_id missing'
    assert page.has_field?("reference-parent-typeahead"),
           '#reference-parent-typeahead missing'
    assert page.has_field?("reference_title"), '#reference_title missing'
    assert page.has_field?("reference_published"),
           '#reference_published missing'
    assert page.has_field?("reference-author-typeahead"),
           '#reference-author-typeahead missing'
    assert page.has_field?("reference_ref_author_role_id"),
           '#reference_ref_author_role_id missing'
    assert page.has_field?("reference_pages"), '#reference_pages missing'
    assert page.has_field?("reference_edition"), '#reference_edition missing'
    assert page.has_field?("reference_volume"), '#reference_volume missing'
    assert page.has_field?("reference_publication_date"),
           '#reference_publication_date missing'
    assert page.has_field?("reference_notes"), '#reference_notes missing'
  end
end
