# frozen_string_literal: true
#   Copyright 2018 Australian National Botanic Gardens
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

class DistributionTest < ActiveSupport::TestCase
  test "display_order" do
    sorted = Distribution.display_order
    assert_not_nil sorted
    assert_equal 6, sorted.size
    assert_equal "Qld", sorted[0].description
    assert_equal 'NSW', sorted[1].description
    assert_equal 'Qld (naturalised)',sorted[2].description
    assert_equal 'NSW (naturalised)', sorted[3].description
    assert_equal 'Qld (?naturalised)', sorted[4].description
    assert_equal 'Qld (extinct)',sorted[5].description
  end

  test "doubtfully naturalised" do
    dist = distributions(:qld_native)
    assert !dist.doubtfully_naturalised?
    dist = distributions(:qld_doubtfully_naturalised)
    assert dist.doubtfully_naturalised?
  end

  test "naturalised" do
    dist = distributions(:qld_naturalised)
    assert dist.naturalised?
    dist = distributions(:qld_doubtfully_naturalised)
    assert !dist.naturalised?
  end

  test "native" do
    dist = distributions(:qld_native)
    assert dist.native?
    dist = distributions(:qld_doubtfully_naturalised)
    assert !dist.native?
  end

  test "extinct" do
    dist = distributions(:qld_extinct)
    assert dist.extinct?
    dist = distributions(:qld_native)
    assert !dist.extinct?
  end

  test "region" do
    dist = distributions(:qld_native)
    assert_equal "Qld", dist.region
    dist = distributions(:qld_naturalised)
    assert_equal "Qld", dist.region
  end

end
