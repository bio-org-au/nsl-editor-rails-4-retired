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

#  A tree element - holds the taxon information
class TreeElement < ActiveRecord::Base
  self.table_name = "tree_element"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :parent_element, class_name: "TreeElement"

  belongs_to :instance, class_name: "Instance"

  belongs_to :name, class_name: "Name"

  has_many :tree_version_elements,
           foreign_key: "tree_element_id"

  def ordered_rank_path
    ranks = NameRank.where("name in (:keyset)", keyset: rank_path.keys).order("sort_order").select("name")
    ranks.collect {|key| rank_path[key.name]['id']}
  end

  # Aim is to supply name objects in tree order while avoiding n-queries.
  def tree_ordered_names
    ordered_rank_path.collect {|item| Name.includes(:name_rank).find(item)}
  end

  def distribution_value
    profile[distribution_key]["value"]
  end

  def distribution?
    distribution_key.present?
  end


  def distribution_key
    profile_key(/Dist/)
  end

  def comment?
    comment_key.present?
  end

  def comment_key
    profile_key(/Comment/)
  end

  def comment_value
    profile[comment_key]["value"]
  end

  def profile_key(regex)
    profile.keys.find {|key| !(regex =~ key).nil?} if profile.present?
  end
end
