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

class FromHybridFormulaToHybridFormulaUnknown2ndParentTest < ActiveSupport::TestCase
  test "convert name from hybrid formula - to - hybrid formula unknown 2nd parent test" do
    name = names(:hybrid_formula)
    assert_equal name.raw_category, Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    assert name.valid?, "hybrid formula name should be valid"

    name.change_category_to = Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
    assert_equal name.category, Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY

    assert_not name.valid?, "hybrid name with 2 parents should not be valid now as a hybrid with unknown 2nd parent"
    assert name.errors.size == 2, "There should be two errors."
    assert name.errors.collect { |k, _v| k.to_s }.include?("name_type_id"), "There should be an error for name_type_id."
    assert name.errors.collect { |k, _v| k.to_s }.include?("second_parent_id"), "There should be an error for second_parent_id."

    name.name_type_id = NameType.find_by(name: "hybrid formula unknown 2nd parent").id
    name.second_parent_id = nil

    assert name.valid?, "hybrid name should now be valid as a hybrid name with unknown 2nd parent"
    name.save!
    assert name.raw_category == Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY, "name should now be a scientific hybrid with unknown 2nd parent"
  end
end
