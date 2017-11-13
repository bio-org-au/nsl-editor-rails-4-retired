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

#  A tree version element - a link table between tree version and tree element
#  The tree version element tells you which tree elements are in this version
#  of a tree. It has a specific identifier called element_link and a taxon
#  identifier called taxon_link

#  A Tree Version Element is a link between the tree version and the tree element.
class TreeVersionElement < ActiveRecord::Base
  self.table_name = "tree_version_element"
  self.primary_key = "element_link"
  self.sequence_name = "nsl_global_seq"

  belongs_to :tree_version,
             foreign_key: "tree_version_id",
             class_name: TreeVersion

  belongs_to :tree_element,
             foreign_key: "tree_element_id",
             class_name: TreeElement

  def parent
    TreeVersionElement.find_by(tree_version_id: tree_version_id,
                               tree_element_id: tree_element.parent_element_id)
  end

  def count_children
    pattern = "^#{tree_element.tree_path}/.*"

    TreeVersionElement.find_by_sql(["select count(tve) c
from tree_version_element tve
  join tree_element te on tve.tree_element_id = te.id
where tve.tree_version_id = ?
  and te.tree_path ~ ?", tree_version_id, pattern]).first['c']
  end

  # returns a record containing identifying information to edit the distribution
  def distribution_record
    record = {}
    record.tree_version_element = self
    record.field_name = tree_element.distribution? ? tree_element.distribution_key : "Distribution"
    record.field_value = if tree_element.distribution?
                           tree_element.distribution_value
                         else
                           "WA, CoI, ChI, AR, CaI, NT, SA, Qld, CSI, NSW, LHI, NI, ACT, Vic, Tas, HI, MDI, MI"
                         end
    record.multiline = false
    record
  end

  def comment_record
    record = new Object
    record.tree_version_element = self
    record.field_name = tree_element.comment? ? tree_element.comment_key : "Comment"
    record.field_value = if tree_element.comment?
                           tree_element.comment_value
                         else
                           ""
                         end
    record.multiline = false
    record
  end


end
