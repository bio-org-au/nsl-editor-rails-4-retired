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

class AuthorTypeaheadsOnNameWildcardsTranslatesAsteriskToPercent < ActiveSupport::TestCase

  test "author typeahead on name wildcards translates asterisk to percent" do
    results = Author::AsTypeahead.on_name('*')
    assert results.size > 0, 'Should be at least one result for asterisk wildcard'
  end
 
end


