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

# encoding: utf-8
require "test_helper"

# Single integration test.
class AvailableFieldsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "create synonymy instance available fields" do
    visit_home_page
    standard_page_assertions
    select "Instances", from: "query-on"
    select "with id", from: "query-field"
    fill_in "search-field", with: instances(:britten_created_angophora_costata).id
    click_on "Search"
    all(".takes-focus").first.click
    big_sleep
    click_on "Synonymy"
    assert page.has_field?("instance-instance-for-name-showing-reference-typeahead"), "Instance name typeahead should be there"
    assert page.has_field?("instance_instance_type_id"), "Instance type field should be there"
    assert page.has_field?("instance_page"), "Instance page field should be there"
    assert page.has_field?("instance_verbatim_name_string"), "Instance verbatim name string field should be there"
    assert page.has_field?("instance_bhl_url"), "Instance BHL URL string field should be there"
  end
end
