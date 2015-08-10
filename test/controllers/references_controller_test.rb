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

class ReferencesControllerTest < ActionController::TestCase
  setup do
    @reference = references(:cavanilles_icones)
  end

  test "references index should route to the catch-all" do
    assert_routing '/references', { controller: "search", action: "index", random: "references"}
  end

  test "referencs new should route to a new referenc" do
    assert_routing '/references/new', { controller: "references", action: "new"}
  end

  test "should route to reference typeahead suggestions by citation" do
    assert_routing '/references/typeahead/on_citation', { controller: "references", action: "typeahead_on_citation"}
  end

  test "should route to show a reference" do
    assert_routing '/references/1', { controller: "references", action: "show", id: "1"}
  end

  test "should show reference" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,{id: @reference,tab: 'tab_show_1'},{username: 'fred', user_full_name: 'Fred Jones', groups: [:edit]})
    assert_response :success
  end

  test "references edit should route to the catch-all" do
    assert_routing '/references/edit/1', { controller: "search", action: "index", random: "references/edit/1"}
  end

  #test "should route to name parent suggestions" do
    #assert_routing '/names/name_parent_suggestions', { controller: "names", action: "name_parent_suggestions" }
  #end
#
  #test "should get name parent suggestions" do
    #@request.headers["Accept"] = "application/javascript"
    #get(:name_parent_suggestions,{rank_id:name_ranks(:unranked).id,term:'search for this'},{username: 'fred', user_full_name: 'Fred Jones', groups: ['edit']})
    #assert_response :success
  #end
#
  #test "should route to typeahead on full name" do
    #assert_routing '/names/typeahead_on_full_name', { controller: "names", action: "typeahead_on_full_name" }
  #end
#
  #test "should get typeahead_on_full_name" do
    #@request.headers["Accept"] = "application/javascript"
    #get(:typeahead_on_full_name,{term:'search for this'},{username: 'fred', user_full_name: 'Fred Jones', groups: ['edit']})
    #assert_response :success
  #end
#
  #test "should route to name hybrid parent suggestions" do
    #assert_routing '/names/hybrid_parent_suggestions', { controller: "names", action: "hybrid_parent_suggestions" }
  #end
#
  #test "should get name hybrid parent suggestions" do
    #@request.headers["Accept"] = "application/javascript"
    #get(:hybrid_parent_suggestions,{rank_id:name_ranks(:unranked).id,term:'search for this'},{username: 'fred', user_full_name: 'Fred Jones', groups: ['edit']})
    #assert_response :success
  #end
#
end


