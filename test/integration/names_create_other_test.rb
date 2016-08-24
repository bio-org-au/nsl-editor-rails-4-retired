#   encoding: utf-8
# frozen_string_literal: true

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

# Test create other name
class NamesCreateOtherTest < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  #########
  # set ups
  #########

  # def fill_autocomplete(field,option)
  # page.execute_script %Q{ $('##{field}').trigger('focus') }
  # page.execute_script %Q{ $('##{field}').trigger('keydown') }
  # selector =
  # %Q{ul.ui-autocomplete li.ui-menu-item a:contains("#{options[:select]}")}
  #
  # page.should have_selector('ul.ui-autocomplete li.ui-menu-item a')
  # page.execute_script %Q{ $('#{selector}').trigger('mouseenter').click() }
  # end

  def fill_in_autocomplete(selector, value)
    script = %{ $('#{selector}').val('#{value}').focus().keypress() }
    page.execute_script(script)
  end

  def choose_autocomplete(text)
    # page.should have_selector(".tt-suggestion p", text: text, visible: false)
    script = %{ $('author .tt-suggestion:contains("#{text}")').click() }
    page.execute_script(script)
  end

  def set_up_an_author(text_field = "sanctioning-author-by-abbrev",
                       id_field = "name_sanctioning_author_id",
                       abbrev = "Benth.", author = authors(:bentham))
    fill_in_text_field(text_field, abbrev)
    script = "document.getElementById('" + id_field + "')
      .setAttribute('type','text')"
    execute_script(script)
    fill_in_id_field(id_field, author.id)
  end

  def assert_successful_create_for(expected_contents, prohibited_contents = [])
    assert page.has_link?("Summary"), "Record not created."
    assert page.has_field?("search-field"), "No search field."
    expected_contents.each do |expected_content|
      assert page.has_content?(expected_content),
             "Missing expected content: #{expected_content}"
    end
    prohibited_contents.each do |prohibited_content|
      assert page.has_no_content?(prohibited_content),
             "Missing prohibited content: #{prohibited_content}"
    end
  end

  def save_name
    find_button("Save").click
  end

  #########

  test "for fields" do
    visit_home_page
    load_new_other_name_form
    assert page.has_field?("name_name_type_id"), "Name type should be there"
    assert page.has_field?("name_name_element"), "Name element should be there"
    assert page.has_field?("name_name_status_id"), "Name status should be there"
    # The following negatives will wait the full time and slow things down, so
    # first reset the wait time.
    default = Capybara.default_wait_time
    Capybara.default_wait_time = 0.1
    assert page.has_no_field?("ex-base-author-by-abbrev"),
           "ex-base-author-by-abbrev should not be there"
    assert page.has_no_field?("base-author-by-abbrev"),
           "base-author-by-abbrev should not be there"
    assert page.has_no_field?("ex-author-by-abbrev"),
           "ex-author-by-abbrev should not be there"
    assert page.has_no_field?("author-by-abbrev"),
           "author-by-abbrev should not be there"
    assert page.has_no_field?("sanctioning-author-by-abbrev"),
           "Sanctioning author field should not be there"
    assert page.has_no_field?("name-parent-typeahead"),
           "Name parent typeahead field should not be there"
    assert page.has_no_field?("name-second-parent-typeahead"),
           "Name second parent typeahead field should not be there"
    assert page.has_no_field?("name_name_rank_id"),
           "Name rank should not be there"
    Capybara.default_wait_time = default
  end

  test "try to save without date for hybrid formula unknown 2nd parent name" do
    names_count = Name.count
    visit_home_page
    load_new_other_name_form
    save_name
    # not sure how to detect the html5 field-required message
    # assert !page.has_link?('Summary'), 'Record created without data!'
    Name.count.must_equal names_count
  end
end
