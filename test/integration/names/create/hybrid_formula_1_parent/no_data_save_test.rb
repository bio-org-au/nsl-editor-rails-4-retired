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

# Single integration test.
class NoDataSaveTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "hybrid formula 1 parent name try to save without data" do
    names_count = Name.count
    visit_home_page
    fill_in "search-field", with: "test: hybrid 1 parent try to save without data"
    load_new_hybrid_formula_unknown_2nd_parent_form
    save_edits
    big_sleep
    Name.count.must_equal names_count, "Record created unexpectedly."
  end
end
