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

class InstancesEditCommentsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  # You create a comment after the instance is created,
  # so it is part of the editing process.
  test 'create instance comment' do
    Capybara.default_driver = :selenium
    sign_in
    standard_page_assertions
    select 'Instances', from: 'query-on'
    select 'for name', from: 'query-field'
    fill_in 'search-field', with: 'a'
    click_on 'Search'
    make_sure_details_are_showing
    debug('matching first')
    Capybara.match = :first
    first_row = find(:css, 'a.show-details-link')
    debug('sending key')
    first_row.native.send_keys :arrow_down
    assert page.has_link?('Adnot.'), 'No "Adnot." heading for tab.'
    click_on 'Adnot.'
    fill_in 'comment_text', with: 'this is a test comment'
    assert_difference('Comment.count') do
      within('#search-result-details') do
        find('#comment-create-btn').click
      end
      assert page.has_content?('- gclarke'), 'No new comment by gclarke.'
      assert page.has_button?('Save'), 'No new comment.'
    end
    Capybara.default_driver = :webkit
  end
end
