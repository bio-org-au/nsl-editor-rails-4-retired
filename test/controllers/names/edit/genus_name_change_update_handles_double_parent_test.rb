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
# require 'sucker_punch/testing/inline'

# Single controller test.
class GenusNameChangeHandlesDoubleParentTest < ActionController::TestCase
  tests NamesController

  # Not correctly creating circumstances of a stale record error
  # such as I get in development if I change the name of Grevillea genus.
  test "genus name change without stale record error" do
    skip "Cannot get the suckerpunch job to run in test."
    grevillea = names(:grevillea_genus)
    descendant = names(:grevillea_cultivar_hybrid)
    assert descendant.parent == grevillea,
           "Grevillea should be the parent for this test."
    assert descendant.second_parent == grevillea,
           "Grevillea should be the second parent for this test."
    @request.headers["Accept"] = "application/javascript"
    att = grevillea.attributes
    att["name_element"] = "xyz"
    post(:update,
         {
           "random_id" => "",
           "category" => "",
           "name" => { "name_type_id" => grevillea.name_type_id,
                       "name_rank_id" => grevillea.name_rank_id,
                       "name_status_id" => grevillea.name_status_id,
                       "parent_typeahead" => grevillea.parent.full_name,
                       "parent_id" => grevillea.parent_id,
                       "name_element" => "XYZ",
                       "ex_base_author_typeahead" => "",
                       "ex_base_author_id" => "",
                       "base_author_typeahead" => "",
                       "base_author_id" => "",
                       "ex_author_typeahead" => "",
                       "ex_author_id" => "",
                       "author_typeahead" => grevillea.author.abbrev,
                       "author_id" => grevillea.author.id,
                       "sanctioning_author_typeahead" => "",
                       "sanctioning_author_id" => "",
                       "duplicate_of_typeahead" => "",
                       "duplicate_of_id" => "",
                       "verbatim_rank" => "" },
           "commit" => "Save",
           "id" => grevillea.id },
         username: "fred", user_full_name: "Fred Jones", groups: ["edit"])
    assert_response :success
    # sleep(2) # to allow for the asynch job
    descendant_after = Name.find(descendant.id)
    assert descendant.full_name != descendant_after.full_name,
           "Grevillea's name change should affect the descendant's name."
  end
end
