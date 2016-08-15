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
class SimpleTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "create simple reference" do
    Capybara.default_driver = :selenium
    reference_count = Reference.count
    visit_home_page
    fill_in "search-field", with: "create simplest reference"
    select_from_menu(%w(New Reference))
    search_result_must_include_content("New reference")
    search_result_details_must_include_content("New Reference")
    select("Book", from: "Type*")
    fill_in("reference_title", with: "Some ref title")
    fill_in_typeahead("reference-author-typeahead",
                      "reference_author_id",
                      "Burbidge, N.T.",
                      authors(:burbidge).id)
    select("Author", from: "Author role*")
    save_new_record
    assert_successful_create_for(["HTML citation for id 1064021178"])
    assert_equal(Reference.count,
                 reference_count + 1,
                 "Wrong reference count after attempted create")
  end
end
