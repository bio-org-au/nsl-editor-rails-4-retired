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

# Test create scientific name
class NamesCreateScientific2Test < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  #########
  # set ups
  #########

  def load_the_form
    click_link "New"
    click_link "Scientific name"
    assert page.has_content?("New Scientific Name"),
           "No New Scientific Name heading."
    assert page.has_field?("name_name_element"), "No name field."
  end

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
    script = %{ $('author .tt-suggestion:contains("#{text}")').click() }
    page.execute_script(script)
  end

  def assert_successful_create_for(expected_contents, prohibited_contents = [])
    Capybara.default_wait_time = 5
    find("#search-field")
    make_sure_details_are_showing
    find("#search-result-details")
    check_expected(expected_contents)
    prohibited_contents.each do |prohibited_content|
      assert page.has_no_content?(prohibited_content),
             "Missing prohibited content: #{prohibited_content}"
    end
  end

  def check_expected
    expected_contents.each do |expected_content|
      assert page.has_content?(expected_content),
             "Missing expected content: #{expected_content}"
    end
  end

  def save_name
    Capybara.match = :first
    find_button("Save").click
  end

  def set_parent
    fill_in_typeahead("name-parent-typeahead",
                      "name_parent_id",
                      "Agenus",
                      names(:a_genus).id)
    find("#search-result-details h4").click
  end

  ########

  test "create scientific name with mismatched base author" do
    names_count = Name.count
    visit_home_page
    fill_in "search-field",
            with: "create scientific name with mismatched author"
    load_the_form
    set_parent
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    fill_in_author_typeahead("base-author-by-abbrev",
                             "name_base_author_id", authors(:burbidge))
    fill_in("name_name_element", with: "Fred")
    fill_in("base-author-by-abbrev", with: "MISMATCHED TEXT")
    save_name
    assert page.has_content?("error"),
           "No error message. Mismatch of base-author not detected"
    assert page.has_content?("1 error prohibited this name from being saved"),
           "Mismatch of base-author: incorrect error message."
    assert page.has_content?("Base Author not specified correctly"),
           "Mismatch of base-author: incorrect typeahead error message."
    Name.count.must_equal names_count
  end

  test "create scientific name with exact match base author abbrev" do
    names_count = Name.count
    visit_home_page
    fill_in "search-field",
            with: "create scientific name with exact match base author abbrev"
    load_the_form
    set_parent
    fill_in_author_typeahead("author-by-abbrev",
                             "name_author_id",
                             authors(:burbidge))
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id",
                             authors(:hooker))
    fill_in("name_name_element", with: "Fred")
    using_wait_time 2 do
      fill_in("base-author-by-abbrev", with: "Benth.")
    end
    save_name
    assert_successful_create_for(["Base Authored by",
                                  "Base Authored by Benth."])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name w exact match upper case base author abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev",
                             "name_author_id", authors(:burbidge))
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    using_wait_time 2 do
      fill_in("base-author-by-abbrev", with: "BENTH.")
    end
    save_name
    assert_successful_create_for(["Base Authored by",
                                  "Base Authored by Benth."])
    Name.count.must_equal names_count + 1
  end

  # start of ex-base-author tests
  test "create scientific name with ex base author" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    fill_in_author_typeahead("base-author-by-abbrev",
                             "name_base_author_id", authors(:burbidge))
    fill_in_author_typeahead("ex-base-author-by-abbrev",
                             "name_ex_base_author_id", authors(:sturm))
    save_name
    assert_successful_create_for(["Authored by",
                                  "Ex Authored by",
                                  "Authored by Benth.",
                                  "Ex Authored by Hook."])
    assert_successful_create_for(["Base Authored by", "Base Authored by Burb."])
    assert_successful_create_for(["Ex Base Authored by",
                                  "Ex Base Authored by SJW"])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name with mismatched ex base author" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    fill_in_author_typeahead("base-author-by-abbrev",
                             "name_base_author_id", authors(:burbidge))
    fill_in("ex-base-author-by-abbrev", with: "MISMATCHED TEXT")
    save_name
    sleep(1)
    assert page.has_content?("error"),
           "No error message. Mismatch of ex-base-author not detected"
    assert page.has_content?("1 error prohibited this name from being saved"),
           "Mismatch of ex-base-author: incorrect error message."
    assert page.has_content?("Ex Base Author not specified correctly"),
           "Mismatch of ex-base-author: incorrect typeahead error message."
    Name.count.must_equal names_count
  end

  test "create sci name ex base auth not expected bec selected then deleted" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    fill_in_author_typeahead("base-author-by-abbrev",
                             "name_base_author_id", authors(:burbidge))
    blank_string = " "
    fill_in("ex-author-by-abbrev", with: blank_string)
    save_name
    assert_successful_create_for([], ["Ex Authored by"])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name with exact match ex base author abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    fill_in_author_typeahead("base-author-by-abbrev",
                             "name_base_author_id", authors(:burbidge))
    using_wait_time 2 do
      fill_in("ex-base-author-by-abbrev", with: "Benth.")
    end
    save_name
    assert_successful_create_for(["Ex Base Authored by",
                                  "Ex Base Authored by Benth."])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name with bad exact match ex base author abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev", "name_author_id")
    fill_in_author_typeahead("ex-author-by-abbrev",
                             "name_ex_author_id", authors(:hooker))
    fill_in_author_typeahead("base-author-by-abbrev",
                             "name_base_author_id", authors(:burbidge))
    using_wait_time 2 do
      fill_in("ex-base-author-by-abbrev", with: "Bxnth.")
    end
    save_name
    sleep(1)
    assert page.has_content?("error"), "No error message."
    assert page.has_content?("1 error prohibited this name from being saved"),
           "Incorrect error message."
    assert page.has_content?("Ex Base Author not specified correctly"),
           "Incorrect error message."
    Name.count.must_equal names_count
  end

  test "create scientific name w exact upper case ex base author abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("author-by-abbrev",
                             "name_author_id", authors(:gaertn))
    using_wait_time 2 do
      fill_in("ex-author-by-abbrev", with: "BENTH.")
    end
    save_name
    assert_successful_create_for(["Ex Authored by", "Ex Authored by Benth."])
    Name.count.must_equal names_count + 1
  end

  # Start of sanctioning author tests
  test "create scientific name with sanctioning author" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("sanctioning-author-by-abbrev",
                             "name_sanctioning_author_id", authors(:bentham))
    save_name
    assert_successful_create_for(["Sanctioned by", "Sanctioned by Benth."])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name with mismatched sanctioning author" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("sanctioning-author-by-abbrev",
                             "name_sanctioning_author_id")
    fill_in("sanctioning-author-by-abbrev", with: "MISMATCHED TEXT")
    save_name
    sleep(1)
    assert page.has_content?("error"), "No error message."
    assert page.has_content?("1 error prohibited this name from being saved"),
           "Incorrect error message."
    assert page.has_content?("Sanctioning Author not specified correctly"),
           "Incorrect error message."
    Name.count.must_equal names_count
  end

  test "create scientific name sanctioning author not expected" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    fill_in_author_typeahead("sanctioning-author-by-abbrev",
                             "name_sanctioning_author_id")
    blank_string = " "
    fill_in("sanctioning-author-by-abbrev", with: blank_string)
    save_name
    assert_successful_create_for([], ["Sanctioned by"])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name with exact match sanctioning author abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    using_wait_time 2 do
      fill_in("sanctioning-author-by-abbrev", with: "Benth.")
    end
    save_name
    assert_successful_create_for(["Sanctioned by", "Sanctioned by Benth."])
    Name.count.must_equal names_count + 1
  end

  test "create scientific name with mismatch sanctioning author abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    using_wait_time 2 do
      fill_in("sanctioning-author-by-abbrev", with: "BXnth.")
    end
    save_name
    sleep(1)
    assert page.has_content?("error"), "No error message."
    assert page.has_content?("1 error prohibited this name from being saved"),
           "Incorrect error message."
    assert page.has_content?("Sanctioning Author not specified correctly"),
           "Incorrect error message."
    Name.count.must_equal names_count
  end

  test "create scientific name with exact match upper case sanct auth abbrev" do
    names_count = Name.count
    visit_home_page
    load_the_form
    fill_in("name_name_element", with: "Fred")
    set_parent
    using_wait_time 2 do
      fill_in("sanctioning-author-by-abbrev", with: "BENTH.")
    end
    save_name
    assert_successful_create_for(["Sanctioned by", "Sanctioned by Benth."])
    Name.count.must_equal names_count + 1
  end
end
