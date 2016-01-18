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

  test "find instances by reference id and instance type of invalid publication" do
    visit_home_page
    select "Instances", from: "query-on"
    select "for reference id", from: "query-field"
    fill_in "search-field", with: references(:de_fructibus_et_seminibus_plantarum).id
    click_on "Search"
    sleep(inspection_time = 0.1)
    assert page.has_content?("6 records"), "Instance search by reference id did not get the expected 6 records."
    assert page.has_content?("De Fructibus et Seminibus Plantarum"), "Instance search by reference id did not get the expected instance."
    assert page.has_content?("[invalid publication]"), "Instance search by reference id did not get the expected invalid publication instance."
    assert page.has_content?("[comb. nov.]"), "Instance search by reference id did not get the expected comb. nov. instance."
  end
end
