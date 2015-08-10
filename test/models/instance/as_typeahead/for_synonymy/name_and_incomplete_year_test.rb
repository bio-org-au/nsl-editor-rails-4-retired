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
require 'models/instance/as_typeahead/for_synonymy/test_helper.rb'

class ForNameAndReferenceYearTest < ActiveSupport::TestCase

  test "name and incomplete year search" do
    results = Instance::AsTypeahead::AsTypeahead.for_synonymy('angophora costata 178')
    assert results.class == Array, "Results should be an array."
    assert results.size >= 2, "Results should include at least two records because incomplete year should be ignored."
    assert results.collect {|r| r[:value]}.include?(Angophora_Costata_De_Fruct_1788_string),Angophora_Costata_De_Fruct_1788_error
    assert results.collect {|r| r[:value]}.include?(Angophora_Costata_Journal_1916_string), Angophora_Costata_Journal_1916_error 
  end

end

