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

class ShowAllNamesTest < ActionDispatch::IntegrationTest

  include Capybara::DSL
 
  test "show all names" do
    visit_home_page
    standard_page_assertions
    select 'Author', from: 'query-on'
    fill_in 'search-field', with: 'Is A Name Authority Of Every Type'
    click_button 'Search'
    sleep(inspection_time = 0.1)
    search_result_must_include_content('Is A Name Authority Of Every Type')
    sleep(inspection_time = 0.1)
    search_result_details_must_include_content('Is A Name Authority Of Every Type')
    search_result_details_must_include_link('1 authored name')
    search_result_details_must_include_link('1 ex-authored name')
    search_result_details_must_include_link('1 base authored name')
    search_result_details_must_include_link('1 ex-base authored name')
    search_result_details_must_include_link('1 sanctioned name')
  end
 
end



