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
class NameStatus < ActiveRecord::Base
  self.table_name = "name_status"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  scope :ordered_by_name, -> { order("replace(name,'[','zzzzzz')") }

  NA = "[n/a]"

  has_many :names

  def self.default
    find_by(name: "legitimate")
  end

  def legitimate?
    name =~ /\Alegitimate\z/
  end

  def manuscript?
    name =~ /\Amanuscript\z/
  end

  def na?
    name =~ /\A\[n\/a\]\z/
  end

  def bracketed_non_legitimate_status
    legitimate? ? "" : "[#{name_without_brackets}]"
  end

  def name_without_brackets
    name.delete("[").gsub(/]/, "")
  end

  def name_for_instance_display
    legitimate? || na? ? "" : name
  end

  def self.not_applicable
    find_by(name: NA).id
  end

  def self.options_for_category(name_category = :unknown, allow_delete = false)
    case name_category
    when Name::SCIENTIFIC_CATEGORY
      scientific_options(allow_delete)
    when Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
      na_and_deleted_options(allow_delete)
    when Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
      na_and_deleted_options(allow_delete)
    when Name::CULTIVAR_HYBRID_CATEGORY
      na_default_and_deleted_options(allow_delete)
    when Name::CULTIVAR_CATEGORY
      na_default_and_deleted_options(allow_delete)
    when Name::OTHER_CATEGORY
      na_and_deleted_options(allow_delete)
    else
      na_and_deleted_options(allow_delete)
    end
  end

  def self.query_form_options
    all.ordered_by_name.collect { |n| [n.name, "status: #{n.name.downcase}"] }.unshift(["any status", ""])
  end

  def self.options(allow_delete = false)
    all.ordered_by_name.collect { |n| [n.name, n.id, disabled: (n.name == "[deleted]" && !allow_delete)] }
  end

  def self.scientific_options(allow_delete = false)
    where(" name not in ('nom. cult.', 'nom. cult., nom. alt.') ").ordered_by_name.collect { |n| [n.name, n.id, disabled: (n.name == "[deleted]" && !allow_delete)] }
  end

  def self.na_and_deleted_options(allow_delete)
    where(" name = '[n/a]' or name = '[deleted]' ").order("name").collect { |n| [n.name, n.id, disabled: n.name == "[deleted]" && !allow_delete] }
  end

  def self.na_default_and_deleted_options(allow_delete)
    where(" name = '[n/a]' or name = '[default]' or name = '[deleted]' ").order("name").collect { |n| [n.name, n.id, disabled: n.name == "[deleted]" && !allow_delete] }
  end
end
