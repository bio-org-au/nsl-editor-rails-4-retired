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

class FromOtherToScientficTest < ActiveSupport::TestCase

  test "convert name from other - to - scientific test" do
    name = names(:other_informal)
    assert_equal name.raw_category, Name::OTHER_CATEGORY
    assert name.valid?, 'other-informal name should be valid'

    name.change_category_to = Name::SCIENTIFIC_CATEGORY
    assert_equal name.category, Name::SCIENTIFIC_CATEGORY

    assert_not name.valid?, 'other-informal name should not be valid now as a scientific name'

    assert name.errors.size == 2, "There should be two errors."
    assert name.errors.collect {|k,v| k.to_s}.include?('name_type_id'), "There should be an error for name_type_id."
    assert name.errors.collect {|k,v| k.to_s}.include?('parent_id'), "There should be an error for parent_id."

    name.name_type_id = NameType.find_by(name: 'autonym').id
    name.parent_id = names(:a_genus).id

    assert name.valid?, "other-informal name should be valid now as a scientific name with a parent"
    name.save!
    assert name.raw_category == Name::SCIENTIFIC_CATEGORY, 'previously other-informal name should now be a scientific name'
  end

end

