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
class NameValidationsParentRankATest < ActiveSupport::TestCase
  test "Regnum takes no parent" do
    assert name_ranks(:regnum).takes_parent? == false,
           "Regnum should take no parent"
  end

  test "Division takes no parent" do
    assert name_ranks(:division).takes_parent? == false,
           "Division should take no parent"
  end

  test "Classis takes no parent" do
    assert name_ranks(:classis).takes_parent? == false,
           "Classis should take no parent"
  end

  test "Subclassis takes no parent" do
    assert name_ranks(:subclassis).takes_parent? == false,
           "Subclassis should take no parent"
  end

  test "Superordo takes no parent" do
    assert name_ranks(:superordo).takes_parent? == false,
           "Superordo should take no parent"
  end

  test "Ordo takes no parent" do
    assert name_ranks(:ordo).takes_parent? == false,
           "Ordo should take no parent"
  end

  test "Subordo takes no parent" do
    assert name_ranks(:subordo).takes_parent? == false,
           "Subordo should take no parent"
  end

  test "Familia takes no parent" do
    assert name_ranks(:familia).takes_parent? == false,
           "Familia should take no parent"
  end

  test "Subfamilia takes parent" do
    assert name_ranks(:subfamilia).takes_parent? == true,
           "Subfamilia should take a parent"
  end

  test "Tribus takes parent" do
    assert name_ranks(:tribus).takes_parent? == true,
           "Tribus should take a parent"
  end

  test "Subtribus takes parent" do
    assert name_ranks(:subtribus).takes_parent? == true,
           "Subtribus should take a parent"
  end

  test "Genus takes parent" do
    assert name_ranks(:genus).takes_parent?, "Genus should take a parent"
  end

  test "Subgenus takes parent" do
    assert name_ranks(:subgenus).takes_parent? == true,
           "Subgenus should take a parent"
    assert name_ranks(:subgenus).parent == name_ranks(:genus),
           "subgenus parent should be genus"
  end

  test "Sectio takes parent" do
    assert name_ranks(:sectio).takes_parent? == true,
           "Sectio should take a parent"
    assert name_ranks(:sectio).parent == name_ranks(:genus),
           "sectio parent should be genus"
  end

  test "Subsectio takes parent" do
    assert name_ranks(:subsectio).takes_parent? == true,
           "Subsectio should take a parent"
    assert name_ranks(:subsectio).parent == name_ranks(:genus),
           "Subsectio parent should be genus"
  end

  test "Series takes parent" do
    assert name_ranks(:series).takes_parent? == true,
           "Series should take a parent"
    assert name_ranks(:series).parent == name_ranks(:genus),
           "Series parent should be genus"
  end

  test "Subseries takes parent" do
    assert name_ranks(:subseries).takes_parent? == true,
           "Subseries should take a parent"
    assert name_ranks(:subseries).parent == name_ranks(:genus),
           "Subseries parent should be genus"
  end
end
