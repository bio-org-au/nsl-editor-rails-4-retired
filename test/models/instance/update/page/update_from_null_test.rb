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

class InstanceUpdatePageFromNullTest < ActiveSupport::TestCase
  test 'update page from null' do
    unchanged = instances(:has_no_page_bhl_url_verbatim_name_string)
    assert unchanged.page.blank?, 'Page should be blank for this test.'
    instance = Instance::AsEdited.find(unchanged.id)
    new_page = 'xzy'
    message = instance.update_if_changed({ 'page' => new_page }, 'fred')
    assert_match /#{new_page}/, instance.page, "New page should be: #{new_page}"
    assert message.match(/\AUpdated/), "Message should be 'Updated' not '#{message}'"
    assert instance.updated_at > unchanged.updated_at, 'Updated date-time should be changed.'
    assert instance.updated_by == 'fred', "Updated by should be 'fred'."
  end
end
