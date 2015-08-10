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

class CreateScientificNameWithBaseAuthorBadExactMatchAuthorAbbrev < ActionDispatch::IntegrationTest

  include Capybara::DSL

    test "create scientific name with bad exact match base author abbrev" do
    names_count = Name.count
    visit_home_page
    load_new_scientific_name_form
    fill_in('name_name_element', with: 'Fred')
    set_name_parent
    fill_in_author_typeahead('author-by-abbrev','name_author_id',authors(:burbidge))
    fill_in_author_typeahead('ex-author-by-abbrev','name_ex_author_id',authors(:hooker))
    using_wait_time 2 do
      fill_in('base-author-by-abbrev', with: 'BXnth.') 
    end
    save_new_record
    sleep(inspection_time = 1)
    assert page.has_content?('error'), 'No error message.'
    assert page.has_content?('1 error prohibited this name from being saved'), 'Incorrect error message.'
    assert page.has_content?('Base Author not specified correctly'), 'Incorrect error message.'
    Name.count.must_equal names_count 
  end

end



