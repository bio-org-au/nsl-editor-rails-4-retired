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

class ParentTypeaheadSelectTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test 'parent typeahead select' do
    Capybara.default_driver = :selenium
    visit_home_page
    fill_in 'search-field', with: 'test: parent typeahead simple'
    select_from_menu(['New', 'Cultivar hybrid name'])
    search_result_must_include_link('New cultivar hybrid name')
    search_result_details_must_include_content('New Cultivar Hybrid Name')
    try_typeahead_single('name-parent-typeahead', 'aforma', 'Aforma | Forma | legitimate')
    the_field = find(:css, 'a.show-details-link')
    first_row.native.send_keys :arrow_down
    Capybara.default_driver = :webkit
  end
end
