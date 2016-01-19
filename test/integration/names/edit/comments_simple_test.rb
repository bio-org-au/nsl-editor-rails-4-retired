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
class NamesEditCommentsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "create name comment" do
    configure_for_webkit
    sign_in
    standard_page_assertions
    fill_in "search-field", with: "create name comment"
    select "Names", from: "query-on"
    fill_in "search-field", with: "*"
    select "just: 1", from: "query-limit"
    click_on "Search"
    make_sure_details_are_showing
    assert page.has_link?("Comments"), "No Comments heading for tab."
    click_on "Comments"
    fill_in "comment_text", with: "this is a test comment"
    assert_difference("Comment.count") do
      click_on "Create"
      big_sleep
      assert page.has_content?("- gclarke"), "No new comment by gclarke."
      assert page.has_css?('input#comment-save-btn'),
             "No 'Save' button so no new comment by gclarke."
      assert page.has_button?("Save"), "No save button so no new comment."
    end
  end
end
