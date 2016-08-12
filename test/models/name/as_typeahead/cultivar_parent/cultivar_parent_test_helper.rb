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

def cultivar_parent_suggestions_should_include(suggestions,
                                               given_rank_name,
                                               expected_rank_name,
                                               caller_test)
  re = Regexp.quote(expected_rank_name)
  assert(suggestions.collect do |h|
    h[:value] =~ /\s#{re}/ ? 1 : 0
  end.sum > 0,
         "suggestions for #{given_rank_name} should
         include #{expected_rank_name} [caller: #{caller_test}]")
end

def cultivar_parent_suggestions_should_not_include(suggestions,
                                                   given_rank_name,
                                                   unexpected_rank_name,
                                                   caller_test)
  re = Regexp.quote(unexpected_rank_name)
  assert_not(suggestions.collect do |h|
    h[:value] =~ /\s#{re}/ ? 1 : 0
  end.sum > 0,
             "suggestions for #{given_rank_name} should not
             include #{unexpected_rank_name} [caller: #{caller_test}]")
end

def cultivar_parent_suggestions_should_only_include(
  suggestions, given_rank_name, expected_rank_names
)
  sorted_name_ranks.each do |rank|
    if expected_rank_names.include?(rank.name)
      cultivar_parent_suggestions_should_include(
        suggestions, given_rank_name, rank.name, caller.first
      )
    else
      cultivar_parent_suggestions_should_not_include(
        suggestions, given_rank_name, rank.name, caller.first
      )
    end
  end
end

def sorted_name_ranks
  NameRank.all.sort { |a, b| a.sort_order <=> b.sort_order }
end

def show(suggestions)
  suggestions.each { |s| print("#{s[:value]}\n") }
end
