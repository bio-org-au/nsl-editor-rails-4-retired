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

# Test create instance.
class InstancesCreateTest < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  test "create instance from scratch" do
    skip("instance create being reworked")
    # instances_count = Instance.count
    # references_count = Reference.count
    # names_count = Name.count
    # visit '/instances'
    # click_link 'Create'
    # Instance.count.must_equal instances_count + 1 , 'Error: failed to add an instance.'
    # Reference.count.must_equal references_count + 1 , 'Error: failed to add a reference.'
    # Name.count.must_equal names_count + 1 , 'Error: failed to add a name.'
  end
end
