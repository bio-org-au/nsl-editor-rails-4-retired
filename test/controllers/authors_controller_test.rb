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

class AuthorsControllerTest < ActionController::TestCase
  setup do
    @bentham = authors(:bentham)
  end
  
  test "authors index should route to the catch-all" do
    assert_routing '/authors', { controller: "search", action: "index", random: "authors"}
  end

  test "authors new should route to a new author" do
    assert_routing '/authors/new', { controller: "authors", action: "new"}
  end

  test "should route to show a author" do
    assert_routing '/authors/1', { controller: "authors", action: "show", id: "1"}
  end

  test "should show author to reader" do
    get(:show,{id: @bentham.id},{username: 'fred', groups: []})
    assert_response :success
  end

  test "should show author to editor" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,{id: @bentham,tab: 'tab_show_1'},{username: 'fred', user_full_name: 'Fred Jones', groups: [:edit]})
    assert_response :success
  end

  test "authors edit should route to the catch-all" do
    assert_routing '/authors/edit/1', { controller: "search", action: "index", random: "authors/edit/1"}
  end

end

