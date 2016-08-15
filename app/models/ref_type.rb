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
class RefType < ActiveRecord::Base
  self.table_name = "ref_type"
  self.primary_key = "id"

  belongs_to :parent, class_name: "RefType", foreign_key: "parent_id"
  has_many :children, class_name: "RefType", foreign_key: "parent_id",
                      dependent: :restrict_with_exception

  has_many :references

  def name?
    name == "Name"
  end

  def unknown?
    name == "Unknown"
  end

  def indefinite_article
    case name.first.downcase
    when "i" then "an"
    when "h" then "an"
    when "u" then "an"
    else "a"
    end
  end

  def self.unknown
    RefType.where(name: "Unknown")
           .push(RefType.order("name").limit(1).first).first
  end

  def self.options
    all.order(:name).collect { |r| [r.name, r.id] }
  end

  def self.options_for_parent_of(children_ref_types)
    children_ref_types.uniq.each do |rt|
      if rt.parent_id.present?
        return options_with_preference(rt.parent.name)
      else
        return options
      end
    end
  end

  def self.options_with_preference(pref)
    all.order(:name)
       .collect do |r|
      if r.name =~ /#{pref}/
        [r.name, r.id, { class: "none" }]
      else
        ["#{r.name} - may be incompatible with child", r.id, { class: "red" }]
      end
    end
  end

  def self.query_form_options
    all.sort { |x, y| x.name <=> y.name }
       .collect { |n| [n.name, n.name.downcase, class: ""] }
  end

  def rule
    rule = if parent_id.blank?
             "cannot be within another reference"
           elsif parent_optional == true
             optional_parent_rule(parent)
           else
             required_parent_rule(parent)
           end
    "#{indefinite_article.capitalize} #{name.downcase} #{rule}."
  end

  def optional_parent_rule(parent)
    "may be within #{parent.indefinite_article} #{parent.name.downcase}"
  end

  def required_parent_rule(parent)
    "should be within #{parent.indefinite_article} #{parent.name.downcase}"
  end

  def parent_allowed?
    parent_id.present?
  end

  def part?
    name.match(/\APart\z/)
  end
end
