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
class ExAuthNotExpectedCozSelectedThenDelTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "create scientific Name: ex auth not expected - selected then deleted" do
    names_count = Name.count
    visit_home_page
    fill_in "search-field",
            with: "create sci Name Ex Auth not expected cause sel then deleted"
    load_new_scientific_name_form
    set_name_parent
    fill_in("name_name_element", with: "Fred")
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    blank_string = " "
    fill_in("ex-author-by-abbrev", with: blank_string)
    save_new_record
    assert_successful_create_for([], ["Ex Authored by"])
    Name.count.must_equal names_count + 1
  end
end
