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

# Name status options tests.
class OptionsForScientificCategoryTest < ActiveSupport::TestCase
  test "should include default" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("[default]"), 'Scientific name status options should include "default"'
  end

  test "should include  [deleted]" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("[deleted]"), 'Scientific name status options should include "[deleted]"'
  end

  test "should include  [n/a]" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("[n/a]"), 'Scientific name status options should include "[n/a]"'
  end

  test "should include  [unknown]" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("[unknown]"), 'Scientific name status options should include "[unknown]"'
  end

  test "should include  isonym" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("isonym"), 'Scientific name status options should include "isonym"'
  end

  test "should include  legitimate" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("legitimate"), 'Scientific name status options should include "legitimate"'
  end

  test "should include  manuscript" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("manuscript"), 'Scientific name status options should include "manuscript"'
  end

  test "should include  nom. alt." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. alt."), 'Scientific name status options should include "nom. alt."'
  end

  test "should include  nom. cons." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. cons."), 'Scientific name status options should include "nom. cons."'
  end

  test "should include  nom. cons., nom. alt." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. cons., nom. alt."), 'Scientific name status options should include "nom. cons., nom. alt."'
  end

  test "should include  nom. cons., orth. cons." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. cons., orth. cons."), 'Scientific name status options should include "nom. cons., orth. cons."'
  end

  test "should not include  nom. cult." do
    assert_not NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. cult."), 'Scientific name status options should not include "nom. cult."'
  end

  test "should not include  nom. cult., nom. alt." do
    assert_not NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. cult., nom. alt."), 'Scientific name status options should not include "nom. cult., nom. alt."'
  end

  test "should include  nom. et orth. cons." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. et orth. cons."), 'Scientific name status options should include "nom. et orth. cons."'
  end

  test "should include  nom. et typ. cons." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. et typ. cons."), 'Scientific name status options should include "nom. et typ. cons."'
  end

  test "should include  nom. illeg." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. illeg."), 'Scientific name status options should include "nom. illeg."'
  end

  test "should include  nom. illeg., nom. rej." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. illeg., nom. rej."), 'Scientific name status options should include "nom. illeg., nom. rej."'
  end

  test "should include  nom. illeg., nom. superfl." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. illeg., nom. superfl."), 'Scientific name status options should include "nom. illeg., nom. superfl."'
  end

  test "should include  nom. inval." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval."), 'Scientific name status options should include "nom. inval."'
  end

  test "should include  nom. inval., nom. alt." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. alt."), 'Scientific name status options should include "nom. inval., nom. alt."'
  end

  test "should include  nom. inval., nom. ambig." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. ambig."), 'Scientific name status options should include "nom. inval., nom. ambig."'
  end

  test "should include  nom. inval., nom. confus." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. confus."), 'Scientific name status options should include "nom. inval., nom. confus."'
  end

  test "should include  nom. inval., nom. dub." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. dub."), 'Scientific name status options should include "nom. inval., nom. dub."'
  end

  test "should include  nom. inval., nom. nud." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. nud."), 'Scientific name status options should include "nom. inval., nom. nud."'
  end

  test "should include  nom. inval., nom. prov." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. prov."), 'Scientific name status options should include "nom. inval., nom. prov."'
  end

  test "should include  nom. inval., nom. subnud." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., nom. subnud."), 'Scientific name status options should include "nom. inval., nom. subnud."'
  end

  test "should include  nom. inval., opera utique oppressa" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., opera utique oppressa"), 'Scientific name status options should include "nom. inval., opera utique oppressa"'
  end

  test "should include  nom. inval., pro syn." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., pro syn."), 'Scientific name status options should include "nom. inval., pro syn."'
  end

  test "should include  nom. inval., tautonym" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. inval., tautonym"), 'Scientific name status options should include "nom. inval., tautonym"'
  end

  test "should include  nom. rej." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. rej."), 'Scientific name status options should include "nom. rej."'
  end

  test "should include  nom. superfl." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nom. superfl."), 'Scientific name status options should include "nom. superfl."'
  end

  test "should include  nomina utique rejicienda" do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("nomina utique rejicienda"), 'Scientific name status options should include "nomina utique rejicienda"'
  end

  test "should include  orth. cons." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("orth. cons."), 'Scientific name status options should include "orth. cons."'
  end

  test "should include  orth. var." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("orth. var."), 'Scientific name status options should include "orth. var."'
  end

  test "should include  typ. cons." do
    assert NameStatus.options_for_category(Name::SCIENTIFIC_CATEGORY).collect(&:first).include?("typ. cons."), 'Scientific name status options should include "typ. cons."'
  end
end
