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

class CanDeleteSynonymIfNoDependentsTest < ActiveSupport::TestCase
  test 'can delete synonym with no dependents' do
    before = Instance.count
    instance = instances(:angophora_lanceolata_cav_in_stanley)
    dependents = Instance.where(cited_by_id: instance.id).count
    assert dependents == 0, "The test fixture should have no dependents but has #{dependents}."
    assert instance.allow_delete?, 'Should be allowed to delete synonym with no dependents.'
  end
end
