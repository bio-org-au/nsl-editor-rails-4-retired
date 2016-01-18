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
class ByReferenceIdAndInstanceTypeInvalidPublicationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "find instances by reference id" do
    visit_home_page
    select "Instances", from: "query-on"
    select "for reference id", from: "query-field"
    fill_in "search-field", with: references(:paper_by_brassard).id
    click_on "Search"
    sleep(inspection_time = 0.1)
    assert page.has_content?("2 records"), "Instance search by reference id did not get just 2 record."
    assert page.has_content?("paper by brassard"), "Instance search by reference id did not get the expected reference."
    assert page.has_content?("Triodia basedowii E.Pritz : xx 200,300 [primary reference]"), "Instance search by reference id did not get the expected instance."
  end
end
