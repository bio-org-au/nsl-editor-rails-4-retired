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
class InstanceTypeUnpublishedCitationOptionsTest < ActiveSupport::TestCase
  setup do
    options = InstanceType.unpublished_citation_options
    assert options.class == Array, "Should be an array."
    assert_equal 3, options.size, "Should be 3 of them."
    @names = options.collect(&:first)
  end

  test "instance type unpublished citation options" do
    test1
    test2
    test3
    test4
    test5
    test6
    test7
    test8
    test9
  end

  def test1
    assert @names.include?("common name"), "Should include common name"
    assert @names.include?("orthographic variant"), sni("orthographic variant")
    assert_not @names.include?("synonym"), sni("synonym")
    assert @names.include?("vernacular name"), "Should include vernacular name"
    assert_not @names.include?("basionym"), "Should not include basionym"
    assert_not @names.include?("doubtful misapplied"),
               "Should not include doubtful misapplied"
  end

  def test2
    assert_not @names.include?("doubtful pro parte misapplied"),
               "Should not include doubtful pro parte misapplied"
    assert_not @names.include?("doubtful pro parte synonym"),
               "Should not include doubtful pro parte synonym"
    assert_not @names.include?("doubtful pro parte taxonomic synonym"),
               "Should not include doubtful pro parte taxonomic synonym"
    assert_not @names.include?("doubtful synonym"), sni("doubtful synonym")
  end

  def test3
    assert_not @names.include?("doubtful taxonomic synonym"),
               "Should not include doubtful taxonomic synonym"
    assert_not @names.include?("isonym"), "Should not include isonym"
    assert_not @names.include?("misapplied"), "Should not include misapplied"
    assert_not @names.include?("nomenclatural synonym"),
               sni("nomenclatural synonym")
    assert_not @names.include?("pro parte misapplied"),
               "Should not include pro parte misapplied"
  end

  def test4
    assert_not @names.include?("pro parte synonym"), sni("pro parte synonym")
    assert_not @names.include?("pro parte taxonomic synonym"),
               "Should not include pro parte taxonomic synonym"
    assert_not @names.include?("replaced synonym"), sni("replaced synonym")
    assert_not @names.include?("taxonomic synonym"),
               "Should not include taxonomic synonym"
  end

  def test5
    assert_not @names.include?("trade name"), "Should not include trade name"
    assert_not @names.include?("[default]"), "Should not include [default]"
    assert_not @names.include?("[n/a]"), "Should not include [n/a]"
    assert_not @names.include?("[unknown]"), "Should not include [unknown]"
    assert_not @names.include?("autonym"), "Should not include autonym"
    assert_not @names.include?("comb. et nom. nov."),
               "Should not include comb. et nom. nov."
  end

  def test6
    assert_not @names.include?("comb. et stat. nov."),
               "Should not include comb. et stat. nov."
    assert_not @names.include?("comb. nov."), "Should not include comb. nov."
    assert_not @names.include?("doubtful invalid publication"),
               "Should not include doubtful invalid publication"
    assert_not @names.include?("doubtful nomenclatural synonym"),
               "Should not include doubtful nomenclatural synonym"
    assert_not @names.include?("excluded name"), sni("excluded name")
  end

  def test7
    assert_not @names.include?("homonym"), "Should not include homonym"
    assert_not @names.include?("implicit autonym"), sni("implicit autonym")
    assert_not @names.include?("invalid publication"),
               "Should not include invalid publication"
    assert_not @names.include?("nom. et stat. nov."),
               "Should not include nom. et stat. nov."
    assert_not @names.include?("nom. nov."), "Should not include nom. nov."
  end

  def test8
    assert_not @names.include?("primary reference"),
               "Should not include primary reference"
    assert_not @names.include?("pro parte nomenclatural synonym"),
               "Should not include pro parte nomenclatural synonym"
    assert_not @names.include?("pro parte replaced synonym"),
               "Should not include pro parte replaced synonym"
    assert_not @names.include?("secondary reference"),
               "Should not include secondary reference"
    assert_not @names.include?("sens. lat."), "Should not include sens. lat."
  end

  def test9
    assert_not @names.include?("tax. nov."), "Should not include tax. nov."
    assert_not @names.include?("comb. et nom. nov."),
               "Should not include comb. et stat. nov."
  end

  def sni(text)
    "Should not include #{text}"
  end
end
