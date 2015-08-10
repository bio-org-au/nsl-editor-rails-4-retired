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

class NameAsEditedDuplicateOfIdWithParialStringMatchingAnotherName < ActiveSupport::TestCase

  test "id with partial string for another name" do
    name_1 = names(:the_regnum)
    name_2 = names(:a_division)
    result = Name::AsEdited.duplicate_of_from_typeahead(name_1.id.to_s,name_2.full_name.chop)
    assert_equal name_2.id, result, "Should get a matching id for the name with matching partial string despite mismatched ID"
  end

end
