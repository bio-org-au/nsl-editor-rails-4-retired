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

class UnrankedCanHaveUnrankedParentTest < ActionDispatch::IntegrationTest

  include Capybara::DSL
  
  test "create unranked with unranked parent" do
    Capybara.default_driver = :selenium
    visit_home_page_as_editor
    fill_in 'search-field', with: 'test: create unranked scientific with unranked parent'
    load_new_scientific_name_form
    fill_in('name_name_element', with: 'with parent of higher rank')
    select '[unranked]', from: 'name_name_rank_id'
    try_typeahead_single('name-parent-typeahead','aforma','Aforma | Forma | legitimate | 1 instance')
    try_typeahead_single('name-parent-typeahead','unranked name 1','unranked name 1 | [unranked] | [unknown] | 0 instances')
  end

end

