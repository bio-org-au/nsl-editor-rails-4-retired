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

class InstanceForEditorShowMostTabsTest < ActionController::TestCase
  tests InstancesController
  setup do
    @instance = instances(:britten_created_angophora_costata)
  end

  test "should show all tab links if editor requests details tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,{id: @instance.id,tab: 'tab_show_1'},{username: 'fred', user_full_name: 'Fred Jones', groups: ['edit']})
    assert_response :success
    assert_select 'li.active a#instance-show-tab', /Details/, "Does not show 'Details' tab link."
    assert_select 'a#instance-edit-tab', /Edit/, "Does not show 'Edit' tab link."
    assert_select 'a#instance-edit-notes-tab', /Notes/, "Does not show 'Notes' tab link."
    assert_select 'a#instance-cite-this-instance-tab', /Syn/, "Does not show 'Syn' tab link."
    assert_select 'a#unpublished-citation-tab', /Unpub/, "Does not show 'Unpub' tab link."
    assert_select 'a#instance-apc-placement-tab', false, "Should not show 'APC' tab link."
    assert_select 'a#instance-comments-tab', /Adnot/, "Does not show 'Adnot' tab link."
  end

end

