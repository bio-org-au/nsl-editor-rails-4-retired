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

# Name rank validation tests.
class NameValidationsParentRankBTest < ActiveSupport::TestCase
  test "Superspecies takes parent" do
    assert name_ranks(:superspecies).takes_parent? == true,
           "Superspecies should take a parent"
    assert name_ranks(:superspecies).parent == name_ranks(:genus),
           "superspecies parent should be genus"
  end

  test "Species takes parent" do
    assert name_ranks(:species).takes_parent? == true,
           "Species should take a parent"
    assert name_ranks(:species).parent == name_ranks(:genus),
           "species parent should be genus"
  end

  test "Subspecies takes parent" do
    assert name_ranks(:subspecies).takes_parent? == true,
           "Subspecies should take a parent"
    assert name_ranks(:subspecies).parent == name_ranks(:species),
           "Subspecies parent should be species"
  end

  test "Nothovarietas takes parent" do
    assert name_ranks(:nothovarietas).takes_parent? == true,
           "Nothovarietas should take a parent"
    assert name_ranks(:nothovarietas).parent == name_ranks(:species),
           "Nothovarietas parent should be species"
  end

  test "Varietas takes parent" do
    assert name_ranks(:varietas).takes_parent? == true,
           "Varietas should take a parent"
    assert name_ranks(:varietas).parent == name_ranks(:species),
           "Varietas parent should be species"
  end

  test "Subvarietas takes parent" do
    assert name_ranks(:subvarietas).takes_parent? == true,
           "Subvarietas should take a parent"
    assert name_ranks(:subvarietas).parent == name_ranks(:species),
           "Subvarietas parent should be species"
  end

  test "Forma takes parent" do
    assert name_ranks(:forma).takes_parent? == true,
           "Forma should take a parent"
    assert name_ranks(:forma).parent == name_ranks(:species),
           "forma parent should be species"
  end

  test "Subforma takes parent" do
    assert name_ranks(:subforma).takes_parent? == true,
           "Subforma should take a parent"
    assert name_ranks(:subforma).parent == name_ranks(:species),
           "subforma parent should be species"
  end

  test "form taxon takes no parent" do
    assert name_ranks(:form_taxon).takes_parent? == false,
           "form taxon should take no parent"
  end

  test "morphological var. takes no parent" do
    assert name_ranks(:morphological_var).takes_parent? == false,
           "morphological var. should take no parent"
  end

  test "nothomorph. takes no parent" do
    assert name_ranks(:nothomorph).takes_parent? == false,
           "nothomorph. should take no parent"
  end

  test "[unranked] takes parent" do
    assert name_ranks(:unranked).takes_parent? == true,
           "[unranked] should take a parent"
    assert name_ranks(:unranked).takes_any_parent? == true,
           "[unranked] should take any parent"
  end

  test "[n/a] takes no parent" do
    assert name_ranks(:na).takes_parent? == false, "[n/a] should take no parent"
  end

  test "[unknown] takes no parent" do
    assert name_ranks(:unknown).takes_parent? == false,
           "[unknown] should take no parent"
  end
end
