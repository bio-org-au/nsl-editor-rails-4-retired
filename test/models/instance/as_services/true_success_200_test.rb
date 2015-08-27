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

class InstanceDeleteServiceTrueSuccess200Test < ActiveSupport::TestCase

  test "instance delete service true success 200" do
    assert_nothing_raised('Should not raise exception if everything is ok') do
      # The test mock service determines response based on the id
      Instance::AsServices.delete(200)
    end
  end
 
end
