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

# Test session deep linking - after login.
class SessionTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "deep linking to a search" do
    configure_for_webkit
    string_1 = "/search?query_on=name&query_field=&query=deep-linking-to-a-"
    string_2 = "search&query_limit=10&query_common_and_cultivar=t"
    visit "#{string_1}#{string_2}"
    # should be redirected to sign in
    sleep(0.2)
    wait_for("#sign-in-form-container", 3)
    if page.has_selector?("#sign-in-form-container")
      assert page.has_content?("Username*"), "No Username field."
      fill_in("sign_in_username", with: "gclarke")
      fill_in("sign_in_password", with: "fred")
      click_button("Sign in")
      sleep(0.2)
      standard_page_assertions
      assert page.has_content?("deep-linking-to-a-search"),
             "Deep linked search not visible - was sign in deep link followed?"
    else
      print("Session was probably already signed in.  Parallel testing?")
    end
  end

  test "invalid authenticity token" do
    configure_for_webkit
    visit "/throw_invalid_authenticity_token"
    assert page.has_content?("Username*"), "No Username field."
    assert page.has_content?("Please try again."),
           "Incorrect or missing stale page message."
  end
end
