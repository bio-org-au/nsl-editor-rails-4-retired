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

class InstanceAsCopierWithNewReferenceStandaloneWithCitationsTest < ActiveSupport::TestCase
  test 'copy a standalone instance with its citers to a new reference' do
    before = Instance.count
    master_instance = Instance::AsCopier.find(instances(:gaertner_created_metrosideros_costata).id)
    assert master_instance.citations.size > 0, 'Master instance should have at least 1 citation.'
    # puts master_instance.id
    # puts master_instance.citations.size
    # puts master_instance.citeds.size
    target_reference = references(:never_used)
    instances_attached_to_new_reference_before = target_reference.instances.count
    instances_attached_to_name_before = master_instance.name.instances.count
    dummy_username = 'fred'
    params = ActionController::Parameters.new(reference_id: target_reference.id.to_s)

    copied_instance = master_instance.copy_with_citations_to_new_reference(params, dummy_username)

    after = Instance.count
    instances_attached_to_new_reference_after = target_reference.instances.count
    instances_attached_to_name_after = master_instance.name.instances.count
    assert_equal instances_attached_to_new_reference_before + 1 + master_instance.reverse_of_this_is_cited_by.size, instances_attached_to_new_reference_after,
                 'Unexpected number of instances attached to the target reference'
    assert_equal instances_attached_to_name_before + 1, instances_attached_to_name_after, 'There should be one extra instance attached to the current name.'
    assert_equal copied_instance.reference_id, target_reference.id, 'The copied instance should link to the new (i.e. target) reference.'
    assert_equal copied_instance.name_id, master_instance.name_id, 'The copied instance should link to the same name as the original instance.'
    assert_equal dummy_username, copied_instance.created_by, 'Create audit should record the expected username.'
    assert_equal dummy_username, copied_instance.updated_by, 'Update audit should record the expected username.'
    assert_equal master_instance.reverse_of_this_is_cited_by.size, copied_instance.reverse_of_this_is_cited_by.size, 'Copied instance should have the same number of relationships.'
    assert_equal before + 1 + master_instance.reverse_of_this_is_cited_by.size, after, 'There should be the correct number of extra instances.'
  end
end
