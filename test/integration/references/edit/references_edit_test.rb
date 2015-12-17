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

class ReferencesEditTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  # Note: this test currently assumes a mock nsl-services server
  # will be running and that the Rails app will be configured
  # to access it.
  test 'edited reference lhs to display pages' do
    visit_home_page
    standard_page_assertions
    select 'References', from: 'query-on'
    fill_in 'search-field', with: 'a'
    select 'just: 1', from: 'query-limit'
    click_on 'Search'
    fill_in 'search-field', with: 'edited reference lhs to display pages'
    all('.takes-focus').first.click
    click_on 'Edit.'
    fill_in 'reference_pages', with: 'test-pages-xyz'
    save_edits
    assert page.has_content?('Updated'), 'No "Updated" message.'
    assert find('#search-result-container').has_content?('test-pages-xyz'), 'Reference pages not displayed in search results after edit.'
    assert find('#search-result-container').has_content?('citation for id 156436017'), 'Reference citation was not reset after edit. (Are the test mock services running and configured?)'
  end
end
