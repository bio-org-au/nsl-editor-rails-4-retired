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

# Name model
class Name < ActiveRecord::Base
  include NameScopable
  include AuditScopable
  include NameCategories
  include NameCategorable
  include NameValidatable
  include NameParentable
  include NameTreeable
  include NameNamable
  include NameAuthorable
  include NameRankable
  include NameEnterable

  strip_attributes
  # acts_as_tree

  self.table_name = "name"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  attr_accessor :display_as,
                :give_me_focus,
                :apc_instance_is_an_excluded_name,
                :apc_declared_bt,
                :change_category_to

  belongs_to :name_type
  belongs_to :name_status
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"

  belongs_to :duplicate_of, class_name: "Name", foreign_key: "duplicate_of_id"
  has_many :duplicates,
           class_name: "Name",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_exception # , order: 'name_element'

  has_many :instances,
           foreign_key: "name_id",
           dependent: :restrict_with_error

  has_many :comments
  has_many :name_tag_names
  has_many :name_tags, through: :name_tag_names
  has_many :name_tree_paths

  SEARCH_LIMIT = 50
  DECLARED_BT = "DeclaredBt".freeze

  before_create :set_defaults
  before_save :validate

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username(attributes, username)
    self.updated_by = username
    update_attributes(attributes)
  end

  def validate
    logger.debug("before save validate - errors: #{errors[:base].size}")
    errors[:base].size.zero?
  end

  def self.exclude_common_and_cultivar_if_requested(exclude)
    if exclude
      not_common_or_cultivar
    else
      where("1=1")
    end
  end

  def only_one_type?
    category == CULTIVAR_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY ||
      category == PHRASE
  end

  def full_name_or_default
    full_name || "[this record has no full name]"
  end

  def display_as_part_of_concept
    self.display_as = :name_as_part_of_concept
  end

  def allow_delete?
    instances.blank? && children.blank? && comments.blank? && duplicates.blank?
  end

  def migrated_from_apni?
    !source_system.blank?
  end

  def anchor_id
    "Name-#{id}"
  end

  def hybrid?
    name_type.hybrid?
  end

  def self.dummy_record
    find_by_name_element("Unknown")
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def cultivar_hybrid?
    category == CULTIVAR_HYBRID_CATEGORY
  end

  def workspace_instance_id(workspace)
    return nil unless workspace.present?
    name_node_tree_link = workspace_name_node_tree_link(workspace)
    return nil unless name_node_tree_link.present? 
    return nil if name_node_tree_link.empty? 
    name_node_tree_link.node.instance_id
  end

  def workspace_name_node_tree_link(workspace)
    Tree::Workspace.find(workspace.id)
                   .find_name_node_link(self)
  end

  private

  def set_defaults
    self.namespace_id = Namespace.default.id if namespace_id.blank?
  end
end
