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

# Instance type options test.
class InstanceTypeSynonymOptionsTest < ActiveSupport::TestCase
  test "instance type synonym options" do
    options = InstanceType.synonym_options
    assert options.class == Array, "Should be an array."
    assert_equal 16, options.size, "Should be 16 of them."
    names = options.collect(&:first)
    assert names.include?("basionym"), "Should include basionym"
    assert names.include?("common name"), "Should include common name"
    assert names.include?("doubtful misapplied"),
           "Should include doubtful misapplied"
    assert names.include?("doubtful pro parte misapplied"),
           "Should include doubtful pro parte misapplied"
    assert_not names.include?("doubtful pro parte synonym"),
               "Should not include doubtful pro parte synonym"
    assert names.include?("doubtful pro parte taxonomic synonym"),
           "Should include doubtful pro parte taxonomic synonym"
    assert_not names.include?("doubtful synonym"),
               "Should not include doubtful synonym"
    assert names.include?("doubtful taxonomic synonym"),
           "Should include doubtful taxonomic synonym"
    assert names.include?("isonym"), "Should include isonym"
    assert names.include?("misapplied"), "Should include misapplied"
    assert names.include?("nomenclatural synonym"),
           "Should include nomenclatural synonym"
    assert names.include?("orthographic variant"),
           "Should include orthographic variant"
    assert names.include?("pro parte misapplied"),
           "Should include pro parte misapplied"
    assert_not names.include?("pro parte synonym"),
               "Should not include pro parte synonym"
    assert names.include?("pro parte taxonomic synonym"),
           "Should include pro parte taxonomic synonym"
    assert names.include?("replaced synonym"), "Should include replaced synonym"
    assert_not names.include?("synonym"), "Should not include synonym"
    assert names.include?("taxonomic synonym"),
           "Should include taxonomic synonym"
    assert names.include?("trade name"), "Should include trade name"
    assert names.include?("vernacular name"), "Should include vernacular name"

    assert_not names.include?("[default]"), "Should not include [default]"
    assert_not names.include?("[n/a]"), "Should not include [n/a]"
    assert_not names.include?("[unknown]"), "Should not include [unknown]"
    assert_not names.include?("autonym"), "Should not include autonym"
    assert_not names.include?("comb. et nom. nov."),
               "Should not include comb. et nom. nov."
    assert_not names.include?("comb. et stat. nov."),
               "Should not include comb. et stat. nov."
    assert_not names.include?("comb. nov."), "Should not include comb. nov."
    assert_not names.include?("doubtful invalid publication"),
               "Should not include doubtful invalid publication"
    assert_not names.include?("doubtful nomenclatural synonym"),
               "Should not include doubtful nomenclatural synonym"
    assert_not names.include?("excluded name"),
               "Should not include excluded name"
    assert_not names.include?("homonym"), "Should not include homonym"
    assert_not names.include?("implicit autonym"),
               "Should not include implicit autonym"
    assert_not names.include?("invalid publication"),
               "Should not include invalid publication"
    assert_not names.include?("nom. et stat. nov."),
               "Should not include nom. et stat. nov."
    assert_not names.include?("nom. nov."), "Should not include nom. nov."
    assert_not names.include?("primary reference"),
               "Should not include primary reference"
    assert_not names.include?("pro parte nomenclatural synonym"),
               "Should not include pro parte nomenclatural synonym"
    assert_not names.include?("pro parte replaced synonym"),
               "Should not include pro parte replaced synonym"
    assert_not names.include?("secondary reference"),
               "Should not include secondary reference"
    assert_not names.include?("sens. lat."), "Should not include sens. lat."
    assert_not names.include?("tax. nov."), "Should not include tax. nov."

    assert_not names.include?("comb. et nom. nov."),
               "Should not include comb. et stat. nov."
  end
end
