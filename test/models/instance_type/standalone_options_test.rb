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

# Instance type options test.
class InstanceTypeStandaloneOptionsTest < ActiveSupport::TestCase
  test "instance type standalone options" do
    options = InstanceType.standalone_options
    assert options.class == Array, "Should be an array."
    assert_equal 10, options.size, "Should be 10 of them."
    names = options.collect(&:first)
    assert names.include?("autonym"), "Should include autonym"
    assert_not names.include?("comb. et nom. nov."), "Should not include comb. et stat. nov."
    assert names.include?("comb. et stat. nov."), "Should include comb. et stat. nov."
    assert names.include?("comb. nov."), "Should include comb. nov."
    assert names.include?("homonym"), "Should include homonym"
    assert names.include?("implicit autonym"), "Should include implicit autonym"
    assert names.include?("nom. et stat. nov."), "Should include nom. et stat. nov."
    assert names.include?("nom. nov."), "Should include nom. nov."
    assert names.include?("primary reference"), "Should include primary reference"
    assert names.include?("primary reference"), "Should include primary reference"
    assert names.include?("tax. nov."), "Should include tax. nov."

    assert_not names.include?("basionym"), "Should not include basionym"
    assert_not names.include?("common name"), "Should not include common name"
    assert_not names.include?("doubtful misapplied"), "Should not include doubtful misapplied"
    assert_not names.include?("doubtful pro parte misapplied"), "Should not include doubtful pro parte misapplied"
    assert_not names.include?("doubtful pro parte synonym"), "Should not include doubtful pro parte synonym"
    assert_not names.include?("doubtful pro parte taxonomic synonym"), "Should not include doubtful pro parte taxonomic synonym"
    assert_not names.include?("doubtful synonym"), "Should not include doubtful synonym"
    assert_not names.include?("doubtful taxonomic synonym"), "Should not include doubtful taxonomic synonym"
    assert_not names.include?("isonym"), "Should not include isonym"
    assert_not names.include?("misapplied"), "Should not include misapplied"
    assert_not names.include?("nomenclatural synonym"), "Should not include nomenclatural synonym"
    assert_not names.include?("orthographic variant"), "Should not include orthographic variant"
    assert_not names.include?("pro parte misapplied"), "Should not include pro parte misapplied"
    assert_not names.include?("pro parte synonym"), "Should not include pro parte synonym"
    assert_not names.include?("pro parte taxonomic synonym"), "Should not include pro parte taxonomic synonym"
    assert_not names.include?("replaced synonym"), "Should not include replaced synonym"
    assert_not names.include?("synonym"), "Should not include synonym"
    assert_not names.include?("taxonomic synonym"), "Should not include taxonomic synonym"
    assert_not names.include?("trade name"), "Should not include trade name"
    assert_not names.include?("vernacular name"), "Should not include vernacular name"
  end
end
