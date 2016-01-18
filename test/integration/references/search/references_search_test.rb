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

# Reference search tests - mostly now split into single files.
class ReferencesSearchTest < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  # test "reference query" do
  # visit references_search_path
  # fill_in('query', with: 'fred')
  # click_on('search')
  # standard_page_assertions
  # expect(page).to have_content('brassard')
  # end

  # "simple"
  test "reference simple search for simple" do
    sign_in
    visit "/search?query=simple&query_on=reference&query_limit=1"
    standard_page_assertions
    sleep(inspection_time = 0.1)
    # page.should have_content('1 record')
    assert page.has_content?("1 record"), "Simple reference search failed."
    # assert page.has_content?('1 record (limited) for "simple"'), 'Simple reference search failed.'
  end

  # # "query=* query_limit=10"
  # test "reference search for simple with correct limit criterion" do
  #   visit '/search?query=*&query_on=reference&query_limit=10'
  #   standard_page_assertions
  #   assert page.has_content?('10 records'), 'Wildcard reference search with limit of 10: criterion failed.'
  # end
  #
  # # "simple limit:"
  # test "reference search for simple with incomplete limit criterion" do
  #   visit '/search?query=simple+limit%3A&query_on=reference&query_limit=100'
  #   standard_page_assertions
  #   assert page.has_content?('0 records'), 'Simple reference search with empty limit: criterion failed.'
  #   assert page.has_content?('for "simple limit:"'), 'Simple reference search with empty limit: criterion failed.'
  #   assert page.has_content?('Ignored criteria: limit)'), 'Simple reference search with empty limit: criterion failed.'
  # end
  #
  # # "distens a:bentham cr-b:7"
  # test "reference advanced search with text and author and created before" do
  #   visit '/search?query=distens+a%3Abentham+cr-b%3A7&query_on=reference&query_limit=100'
  #   standard_page_assertions
  #   assert page.has_content?('1 record'), 'Search result for reference "distens a:bentham cr-b:7" not found.'
  #   assert page.has_content?('distens a:bentham cr-b:7'), 'Search result for reference "distens a:bentham cr-b:7" not found.'
  # end
  #
  # # "distens a:bentham cr-b:"
  # test "reference advanced search with empty criterion " do
  #   visit '/search?query=distens+a%3Abentham+cr-b%3A&query_on=reference&query_limit=100'
  #   standard_page_assertions
  #   assert page.has_content?('0 records'), 'Search result for reference "distens a:bentham cr-b:" not found. Test for empty criterion'
  #   assert page.has_content?('distens a:bentham cr-b:'), 'Search result for reference "distens a:bentham cr-b:" not found. Test for empty criterion'
  #   assert page.has_content?('(Ignored criteria: cr-b)'), 'Search result for reference "distens a:bentham cr-b:" not found. Test for empty criterion'
  # end
end
