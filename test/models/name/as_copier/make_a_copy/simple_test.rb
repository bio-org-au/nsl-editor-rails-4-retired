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

class NameAsCopierMakeACopySimpleTest < ActiveSupport::TestCase
  test 'copy one name' do
    before = Name.count
    master_name = Name::AsCopier.find(names(:a_genus_with_two_instances).id)
    dummy_name_element = 'xyz'
    dummy_username = 'fred'
    copied_name = master_name.copy_with_username(dummy_name_element, dummy_username)
    after = Name.count
    assert_equal before + 1, after, 'There should be one extra name.'
    assert_equal master_name.name_type_id, copied_name.name_type_id
    assert_equal master_name.name_rank_id, copied_name.name_rank_id
    assert_equal master_name.name_status_id, copied_name.name_status_id
    assert_equal master_name.namespace_id, copied_name.namespace_id
    assert_equal master_name.author_id, copied_name.author_id
    assert_equal master_name.base_author_id, copied_name.base_author_id
    assert_equal master_name.ex_author_id, copied_name.ex_author_id
    assert_equal master_name.ex_base_author_id, copied_name.ex_base_author_id
    assert_equal master_name.sanctioning_author_id, copied_name.sanctioning_author_id
    assert_equal master_name.orth_var, copied_name.orth_var
    assert_equal master_name.parent_id, copied_name.parent_id
    assert_equal master_name.second_parent_id, copied_name.second_parent_id
    assert_equal master_name.verbatim_rank, copied_name.verbatim_rank
    assert_match dummy_name_element, copied_name.name_element
    assert_equal dummy_username, copied_name.created_by
    assert_equal dummy_username, copied_name.updated_by
  end
end
