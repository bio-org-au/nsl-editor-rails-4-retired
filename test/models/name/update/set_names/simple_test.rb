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

class NameUpdateSetNamesSimpleTest < ActiveSupport::TestCase
  test "name update set names simple" do
    name = names(:a_species)
    name.name_element = "xyz"
    name.save!
    name.set_names!
    updated_name = Name.find(name.id)
    assert_equal "full name for id #{name.id}", name.full_name, "Full name not set - make sure the test mock server is running."
    assert_equal "full name for id #{name.id}", updated_name.full_name, "Full name not set"
    assert_equal "full marked up name for id #{name.id}", updated_name.full_name_html, "Full name html not set"
    assert_equal "simple name for id #{name.id}", updated_name.simple_name, "Simple name not set"
    assert_equal "simple marked up name for id #{name.id}", updated_name.simple_name_html, "Simple name html not set"
  end
end
