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

class NamesEditTest < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  #########
  # set ups
  #########

  def load_the_form
    click_link "New"
    click_link "Other name"
    find_link("New other name").click
    assert page.has_content?("New Name"), "No new name."
    assert page.has_content?("New other name"), "No new other name."
    assert page.has_field?("search-field"), "No search field."
  end

  # def fill_autocomplete(field,option)
  # page.execute_script %Q{ $('##{field}').trigger('focus') }
  # page.execute_script %Q{ $('##{field}').trigger('keydown') }
  # selector = %Q{ul.ui-autocomplete li.ui-menu-item a:contains("#{options[:select]}")}
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
                       abbrev = "Benth.",
                       author = authors(:bentham))
    using_wait_time 20 do
      fill_in(text_field, with: abbrev)
    end
    script = "document.getElementById('" + id_field + "').setAttribute('type','text')"
    execute_script(script)
    using_wait_time 20 do
      fill_in(id_field, with: author.id)
    end
  end

  def makeHiddenFieldAvailable(id)
    script = "document.getElementById('" + id + "').setAttribute('type','text')"
    execute_script(script)
  end

  def assert_successful_create_for(expected_contents, prohibited_contents = [])
    assert page.has_link?("Summary"), "Record not created."
    assert page.has_field?("search-field"), "No search field."
    expected_contents.each do |expected_content|
      assert page.has_content?(expected_content), "Missing expected content: #{expected_content}"
    end
    prohibited_contents.each do |prohibited_content|
      assert page.has_no_content?(prohibited_content), "Missing prohibited content: #{prohibited_content}"
    end
  end

  def save_name
    find_button("Save").click
  end

  #########

  test "simple edit" do
    names_count = Name.count
    visit_home_page
    fill_in("query", with: "Triodia basedowii")
    click_button("Search")
    assert find_link("Edit").visible?, "Edit link not visible"
    sleep(inspection_time = 4)
    find_link("Edit").click
    sleep(inspection_time = 10)
    # load_the_form
    # save_name
  end
end
