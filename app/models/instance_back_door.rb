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
class InstanceBackDoor < ActiveRecord::Base
  self.table_name = "instance"
  self.primary_key = "id"

  def change_reference(params, username)
    InstanceBackDoor.transaction do
      self.reference_id = params["reference_id"]
      self.updated_by = username
      save
      InstanceBackDoor
        .find_by_sql(["select * from instance where cited_by_id = ?", id])
        .each do |instance|
        instance.reference_id = params["reference_id"]
        instance.updated_by = username
        instance.save
      end
    end
  end
end
