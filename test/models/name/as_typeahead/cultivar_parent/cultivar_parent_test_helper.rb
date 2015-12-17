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

def cultivar_parent_suggestions_should_include(suggestions, given_rank_name, expected_rank_name, caller_test)
  assert(suggestions.collect { |h| h[:value].match(/\s#{Regexp.quote(expected_rank_name)}/) ? 1 : 0 }.sum > 0, "suggestions for #{given_rank_name} should include #{expected_rank_name} [caller: #{caller_test}]")
  end

def cultivar_parent_suggestions_should_not_include(suggestions, given_rank_name, unexpected_rank_name, caller_test)
  assert_not(suggestions.collect { |h| h[:value].match(/\s#{Regexp.quote(unexpected_rank_name)}/) ? 1 : 0 }.sum > 0, "suggestions for #{given_rank_name} should not include #{unexpected_rank_name} [caller: #{caller_test}]")
end

def cultivar_parent_suggestions_should_only_include(suggestions, given_rank_name, expected_rank_names)
  caller_test = caller.first
  NameRank.all.sort { |a, b| a.sort_order <=> b.sort_order }.each do |rank|
    if expected_rank_names.include?(rank.name)
      cultivar_parent_suggestions_should_include(suggestions, given_rank_name, rank.name, caller_test)
    else
      cultivar_parent_suggestions_should_not_include(suggestions, given_rank_name, rank.name, caller_test)
    end
  end
end

def show(suggestions)
  suggestions.each { |s| print("#{s[:value]}\n") }
end
