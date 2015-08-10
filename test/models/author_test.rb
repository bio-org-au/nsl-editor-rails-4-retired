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
 
class AuthorTest < ActiveSupport::TestCase

  test "typeahead on name should exclude authors with abbrev including those with empty string abbrev" do
    typeahead = Author::AsTypeahead.on_name('for typeahead on name')
    assert_instance_of(Array,typeahead,'Typeahead on name should return an array') 
    typeahead_ids = typeahead.collect{|val| val[:id].to_i}
    assert_includes(typeahead_ids,
                    authors(:for_typeahead_on_name_null_abbrev).id,
                    'Author should be in typeahead list')
    assert_includes(typeahead_ids,
                        authors(:for_typeahead_on_name_has_abbrev).id,
                        'Author should be in typeahead list')
    assert_includes(typeahead_ids,
                    authors(:for_typeahead_on_name_empty_string_abbrev).id,
                    'Author with empty string abbrev should be in typeahead list')

  end

  test "author exact abbrev with a unique abbreviation" do
    assert(Author::AsQuery.exact_abbrev?("#{authors(:unique_abbrev).abbrev}"), 'Author abbreviation should match just one author.')
  end
 
  test "author with exact abbrev with a unique abbreviation is correct" do
    assert(Author::AsQuery.with_exact_abbrev("#{authors(:unique_abbrev).abbrev}").id == authors(:unique_abbrev).id , 'Author ids should match.')
  end

  test "author exact abbrev with a non-unique abbreviation" do
    assert_not(Author::AsQuery.exact_abbrev?("#{authors(:duplicate_abbrev_1).abbrev}"), 'Author abbreviation should not match just one author.')
  end
 
  test "author with exact abbrev with a non-unique abbreviation is correct" do
    assert_not(Author::AsQuery.with_exact_abbrev("#{authors(:duplicate_abbrev_1).abbrev}").id == authors(:unique_abbrev).id , 'Author ids should not match.')
  end
 
end

