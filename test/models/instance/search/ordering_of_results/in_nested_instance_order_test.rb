# frozen_string_literal: true
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

# Single instance model test.
class InNestedInstanceOrderTest < ActiveSupport::TestCase
  def assert_with_args(results, index, expected)
    assert(
      /\A#{Regexp.escape(expected)}\z/.match(results[index].instance_type.name),
      "Wrong at index #{index}; should be: #{expected}
      NOT #{results[index].instance_type.name}"
    )
  end

  test "instances in nested instance type order" do
    results = Instance.joins(:instance_type)
                      .where(
                        instance_type: {
                          name:
                          ["basionym",
                           "common name",
                           "vernacular name",
                           "doubtful nomenclatural synonym",
                           "nomenclatural synonym",
                           "doubtful taxonomic synonym",
                           "taxonomic synonym",
                           "doubtful pro parte nomenclatural synonym",
                           "pro parte nomenclatural synonym",
                           "pro parte taxonomic synonym",
                           "doubtful pro parte taxonomic synonym"]
                        }
                      ).
              # extra order clause to make definitive and
              # repeatable ordering for these tests
              in_nested_instance_type_order.order("instance_type.name")

    # results.each_with_index do |i,ndx|
    #   puts "#{ndx}: #{i.instance_type.name}" if ndx < 30
    # end
    assert_with_args(results, 0, "basionym")
    assert_with_args(results, 1, "basionym")
    assert_with_args(results, 2, "doubtful nomenclatural synonym")
    assert_with_args(results, 3, "doubtful pro parte taxonomic synonym")
    assert_with_args(results, 4, "doubtful taxonomic synonym")
    assert_with_args(results, 5, "nomenclatural synonym")
    assert_with_args(results, 6, "nomenclatural synonym")
    assert_with_args(results, 7, "pro parte nomenclatural synonym")
    assert_with_args(results, 8, "taxonomic synonym")
    assert_with_args(results, 9, "common name")
    assert_with_args(results, 10, "common name")
    assert_with_args(results, 11, "vernacular name")
  end
end
