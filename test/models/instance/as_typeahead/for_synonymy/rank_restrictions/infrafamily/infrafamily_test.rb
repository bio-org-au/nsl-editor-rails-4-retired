# frozen_string_literal: true

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
require "models/instance/as_typeahead/for_synonymy/rank_restrictions/\
infrafamily/infrafamily_helper"

# Single instance typeahead search.
class TypeaheadForSynonymyInfrafamilyTest < ActiveSupport::TestCase
  def setup
    @ta = Instance::AsTypeahead::ForSynonymy.new(
      "*",
      names(:an_infrafamily_with_an_instance).id
    )
  end

  test "instance typeahead for synonymy rank restriction for an infrafamily" do
    assert @ta.results.size >= 2, "Should be at least 2 synonyms for angophora"
    @rank_names = @ta.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    check_infrafamily_exclusions
    check_infrafamily_inclusions
  end
end
