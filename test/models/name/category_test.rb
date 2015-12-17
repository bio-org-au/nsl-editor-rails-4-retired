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

class CategoryTest < ActiveSupport::TestCase
  test 'scientific category' do
    assert Name::SCIENTIFIC_CATEGORY == 'scientific', "Name::SCIENTIFIC_CATEGORY should equal 'scientific'"
  end

  test 'scientific hybrid formula category' do
    assert Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY == 'scientific hybrid formula', "Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY should equal 'scientific hybrid formula'"
  end

  test 'scientific hybrid formula unknown 2nd parent category' do
    assert Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY == 'scientific hybrid formula unknown 2nd parent',
           "Name::SCIENTIFIC_HYBRID_FORMULA_unknown 2nd parent CATEGORY should equal 'scientific hybrid formula unknown 2nd parent'"
  end

  test 'cultivar category' do
    assert Name::CULTIVAR_CATEGORY == 'cultivar', "Name::CULTIVAR_CATEGORY should equal 'cultivar'"
  end

  test 'cultivar hybrid category' do
    assert Name::CULTIVAR_HYBRID_CATEGORY == 'cultivar hybrid', "Name::CULTIVAR_HYBRID_CATEGORY should equal 'cultivar hybrid'"
  end

  test 'other category' do
    assert Name::OTHER_CATEGORY == 'other', "Name::OTHER_CATEGORY should equal 'other'"
  end
end
