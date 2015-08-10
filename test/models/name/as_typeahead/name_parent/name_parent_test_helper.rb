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


  def suggestions_should_include(suggestions,given_rank_name,expected_rank_name)
    # rank is the second field in the pipe-separated string
    assert(suggestions.collect {|h| h[:value].split('|')[1].strip.match(/\A#{Regexp.quote(expected_rank_name)}\z/) ? 1 : 0 }.sum > 0, "suggestions for #{given_rank_name} should include #{expected_rank_name}")
  end

  def suggestions_should_not_include(suggestions,given_rank_name,unexpected_rank_name)
    assert_not(suggestions.collect do |h| 
      # rank is the second field in the pipe-separated string
      rank = h[:value].split('|')[1].strip
      rank.match(/\A#{Regexp.quote(unexpected_rank_name)}\z/) ? 1 : 0 
    end.sum > 0, "suggestions for #{given_rank_name} should not include #{unexpected_rank_name}")
  end

  def suggestions_should_only_include(suggestions,given_rank_name,expected_rank_names)
    NameRank.all.sort{|a,b| a.sort_order <=> b.sort_order}.each do |rank|
      if expected_rank_names.include?(rank.name)
        suggestions_should_include(suggestions,given_rank_name,rank.name)
      else
        suggestions_should_not_include(suggestions,given_rank_name,rank.name)
      end
    end
  end

