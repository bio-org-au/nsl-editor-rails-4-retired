#   encoding: utf-8

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

class ForMullerWithUmlautAdvancedInlineTest < ActiveSupport::TestCase

  test "inline advanced search for muller with umlaut using umlaut" do
    results, rejected_pairings,is_limited,focus_anchor_id,info = Author::AsSearchEngine.search("a: fr.müLl")
    assert_equal results.class, Author::ActiveRecord_Relation, "Results should be a Author::ActiveRecord_Relation."
    assert_equal 1, results.size, "Exactly 1 result is expected."
    assert_equal authors(:muller_f_with_umlaut).name, results.first[:name]
  end

  test "inline advanced search for muller with umlaut using u" do
    results, rejected_pairings,is_limited,focus_anchor_id,info = Author::AsSearchEngine.search("a: fr.muLl")
    assert_equal results.class, Author::ActiveRecord_Relation, "Results should be a Author::ActiveRecord_Relation."
    assert_equal 1, results.size, "Exactly 1 result is expected - perhaps müll wasn't found"
    assert_equal authors(:muller_f_with_umlaut).name, results.first[:name]
  end

end



