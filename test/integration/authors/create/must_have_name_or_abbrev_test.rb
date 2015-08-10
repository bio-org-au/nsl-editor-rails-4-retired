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

class MustHaveNameOrAbbrevTest < ActionDispatch::IntegrationTest

  include Capybara::DSL
  
  test "no save and error message if neither name nor abbrev" do
    authors_count = Author.count
    visit_home_page
    fill_in 'search-field', with: 'create name with neither name nor abbrev'
    load_new_author_form
    save_new_record
    search_result_details_must_include_content("2 errors prohibited this author from being saved:")
    search_result_details_must_include_content("Name can't be blank if abbrev is blank.")
    search_result_details_must_include_content("Abbrev can't be blank if name is blank.")
    assert_equal(Author.count,authors_count,'Wrong name count')
  end




end


