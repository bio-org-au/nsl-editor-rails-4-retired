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

require 'test_helper'

class AvailableFieldsTest < ActionDispatch::IntegrationTest

  include Capybara::DSL

  test "create standalone instance available fields" do
    visit_home_page
    standard_page_assertions
    select 'Names', from: 'query-on'
    fill_in 'search-field', with: "*"
    select 'just: 1', from: 'query-limit'
    click_on 'Search'
    all('.takes-focus').first.click
    big_sleep
    click_on 'New instance'
    big_sleep
    assert page.has_field?('instance-reference-typeahead'), 'Instance reference typeahead should be there'
    assert page.has_field?('instance_page'), 'Instance page field should be there'
    assert page.has_field?('instance_instance_type_id'), 'Instance type field should be there'
    assert page.has_field?('instance_verbatim_name_string'), 'Instance verbatim name string field should be there'
    assert page.has_field?('instance_bhl_url'), 'Instance BHL URL string field should be there'
  end

end


