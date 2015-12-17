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

class MustHaveSecondParentTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test 'must have second parent' do
    names_count = Name.count
    visit_home_page
    fill_in 'search-field', with: 'test: must have second parent test'
    load_new_cultivar_hybrid_name_form

    set_name_parent
    fill_in('name_name_element', with: 'Fred')

    save_new_record
    sleep(inspection_time = 1)
    # Do not know how to test for the HTML5 required field test.
    Name.count.must_equal names_count
  end
end
