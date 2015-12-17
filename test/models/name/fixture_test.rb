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

class FixtureTest < ActiveSupport::TestCase
  test 'fixture unknown species name should be valid' do
    name = names(:unknown_species)
    assert name.valid?, "Fixture unknown_species name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture another species name should be valid' do
    name = names(:another_species)
    assert name.valid?, "Fixture another_species name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture triodia_basedowii name should be valid' do
    name = names(:triodia_basedowii)
    assert name.valid?, "Fixture triodia_basedowii name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture crotalaria_distans name should be valid' do
    name = names(:crotalaria_distans)
    assert name.valid?, "Fixture crotalaria_distans name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture acacia name should be valid' do
    name = names(:acacia)
    assert name.valid?, "Fixture acacia name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture argyle_apple name should be valid' do
    name = names(:argyle_apple)
    assert name.valid?, "Fixture argyle_apple name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture var_tuberosus name should be valid' do
    name = names(:var_tuberosus)
    assert name.valid?, "Fixture var_tuberosus should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture nom inval andrewsianum name should be valid' do
    name = names(:nom_inval_andrewsianum)
    assert name.valid?, "Fixture nom_inval_andrewsianum name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture scientific name should be valid' do
    name = names(:scientific_name)
    assert name.valid?, "Fixture scientific name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture the_regnum name should be valid' do
    name = names(:the_regnum)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture the_regnum name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_division name should exist and should be valid' do
    name = names(:a_division)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_division name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_classis name should be valid' do
    name = names(:a_classis)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_classis name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subclassis name should be valid' do
    name = names(:a_subclassis)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subclassis name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_superordo name should be valid' do
    name = names(:a_superordo)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_superordo name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture an_ordo name should be valid' do
    name = names(:an_ordo)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture an_ordo name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_family name should be valid' do
    name = names(:a_family)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_family name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subfamilia name should be valid' do
    name = names(:a_subfamilia)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subfamilia name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_tribus name should be valid' do
    name = names(:a_tribus)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_tribus name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subtribus name should be valid' do
    name = names(:a_subtribus)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subtribus name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a genus name should be valid' do
    name = names(:a_genus)
    assert name.valid?, "Fixture a_genus name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subgenus name should be valid' do
    name = names(:a_subgenus)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subgenus name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_sectio name should be valid' do
    name = names(:a_sectio)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_sectio name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subsectio name should be valid' do
    name = names(:a_subsectio)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subsectio name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_series name should be valid' do
    name = names(:a_series)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_series name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subseries name should be valid' do
    name = names(:a_subseries)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subseries name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_superspecies name should be valid' do
    name = names(:a_superspecies)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_superspecies name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_species name should be valid' do
    name = names(:a_species)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_species name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subspecies name should be valid' do
    name = names(:a_subspecies)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subspecies name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_nothovarietas name should be valid' do
    name = names(:a_nothovarietas)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_nothovarietas name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_varietas name should be valid' do
    name = names(:a_varietas)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_varietas name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subvarietas name should be valid' do
    name = names(:a_subvarietas)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subvarietas name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_forma name should be valid' do
    name = names(:a_forma)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_forma name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture a_subforma name should be valid' do
    name = names(:a_subforma)
    assert name.present?, 'No such name'
    assert name.valid?, "Fixture a_subforma name should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end

  test 'fixture scientific name without author should be valid' do
    name = names(:scientific_name_without_author)
    assert name.valid?, "Fixture scientific name without author should be valid.  Errors: #{name.errors.full_messages.join('; ')}"
  end
end
