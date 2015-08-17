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

class NameCreateScientificHybridFormulaTest < ActiveSupport::TestCase

  test "simple" do
    name_type = name_types(:hybrid_formula_parents_known)
    name_rank = name_ranks(:species)
    name_status = name_statuses(:na)
    name_params = {"name_type_id"=>"#{name_type.id}", 
                   "name_rank_id"=>"#{name_rank.id}", 
                   "name_status_id"=>"#{name_status.id}"} 
    parent = names(:a_species)
    second_parent = names(:another_species)
    typeahead_params = {"parent_typeahead"=>"#{parent.full_name} | Species", 
                        "parent_id"=>"#{parent.id}", 
                        "second_parent_typeahead"=>"#{second_parent.full_name} | Species", 
                        "second_parent_id"=>"#{second_parent.id}", 
                        "verbatim_rank"=>"sdfdf"}
    
    name = Name::AsEdited.create(name_params,typeahead_params,'fred')
    assert name.valid?, "New name should be valid without authors. Errors: #{name.errors.full_messages.join('; ')}"
  end
 
end

