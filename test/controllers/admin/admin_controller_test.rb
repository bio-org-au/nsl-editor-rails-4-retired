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

class AdminControllerTest < ActionController::TestCase
  setup do
  end
  
  test "editor should not get index" do
    get(:index,{},{username: 'fred', user_full_name: 'Fred Jones', groups: [:edit]})
    assert_response :forbidden
  end
  
  test "admin user should get index" do
    get(:index,{},{username: 'fred', user_full_name: 'Fred Jones', groups: ['admin']})
    assert_response :success
    assert_select 'h2', 'Admin', "Should have 'Admin' heading."
  end
 
end



