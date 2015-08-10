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

class ReferencesDeleteTest < ActionDispatch::IntegrationTest

  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  def search_result_must_include(link_text, msg)
    #assert find('div#search-result-container').has_link?(/#{link_text}/i), msg                # Does not work with has_link?  
    assert find('div#search-result-container').has_content?(/#{link_text}/i), msg                # Does not work with has_link?  
  end

  test "delete button if no children" do
    visit_home_page
    standard_page_assertions
    select 'Reference', from: 'query-on'
    fill_in 'search-field', with: 'Book by Blume'
    click_button 'Search'
    all('.takes-focus').first.click
    search_result_must_include('Book by Blume','Reference search should have returned a record for "Book by Blume".')
    click_link 'Edit...'
    sleep(inspection_time = 1)
    assert find("#search-result-details").has_content?(/DOI/), 'Edit... tab not visible.'
    assert find("#search-result-details").has_content?(/Delete the reference.../), 'Delete button should be visible.'
  end
 
  test "no delete button if children" do
    visit_home_page
    standard_page_assertions
    select 'Reference', from: 'query-on'
    fill_in 'search-field', with: 'Journal by Blume'
    click_button 'Search'
    all('.takes-focus').first.click
    search_result_must_include('Journal by Blume, C.L. .von. .Editor','Reference search should have returned a record for "Journal by Blume, C.L. [von] (Editor)".')
    click_link 'Edit...'
    sleep(inspection_time = 1)
    assert find("#search-result-details").has_content?(/DOI/), 'Edit... tab not visible.'
    assert_not find("#search-result-details").has_content?(/Delete the reference.../), 'Delete button should not be visible.'
  end
 
end

