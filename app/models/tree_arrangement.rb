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

#  A tree - usually a classification or a classification workspace

class TreeArrangement < ActiveRecord::Base
  self.table_name = "tree_arrangement"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :base_arrangement, class_name: TreeArrangement

  def find_placement_of_name(name)
    link_id = TreeArrangement::sp_find_name_in_tree(name.id, id)
    TreeLink.find(link_id)
  end

  def editableBy?(user)
    user && tree_type == 'U' && user.groups.include?(base_arrangement.label)
  end

  def derivedLabel()
    case
      when tree_type =='P' then label
      when tree_type == 'U' then base_arrangement.derivedLabel
      else "##{id}"
    end
  end

  def self.sp_find_name_in_tree(name_id, tree_id)
    # doing this as bind variables isn't working for me, and anyway
    # it doesn't matter because this select doen't involve a lot of planning
    connection.select_value("select find_name_in_tree(#{name_id}, #{tree_id})")
  end
end
