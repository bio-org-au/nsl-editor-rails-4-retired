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

# Single name model test.
class NameAsServicesDeleteURLTest < ActiveSupport::TestCase
  test "url" do
    url = Name::AsServices.delete_url(12_345, "this is the reason.....")
    request = %(#{Rails.configuration.name_services}12345/api/delete)
    api_key = %(apiKey=#{Rails.configuration.api_key})
    reason = %(reason=this%20is%20the%20reason.....)
    re = Regexp.escape(%(#{request}?#{api_key}&#{reason}))
    assert url.match(re), "URL is wrong."
  end
end
