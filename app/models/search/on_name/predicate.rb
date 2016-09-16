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
class Search::OnName::Predicate
  attr_reader :canon_field,
              :canon_value,
              :trailing_wildcard,
              :leading_wildcard,
              :multiple_values,
              :predicate,
              :value_frequency,
              :processed_value,
              :tokenize,
              :field,
              :value,
              :has_scope,
              :scope_,
              :order,
              :allow_common_and_cultivar

  def initialize(field, value)
    @field = field
    @value = value
    @canon_field = build_canon_field(field)
    rule = Search::OnName::FieldRule::RULES[@canon_field] || EMPTY_RULE
    apply_rule(rule)
    @canon_value = build_canon_value(value)
    apply_scope
    @order = rule[:order] || "sort_name"
    process_value
    @tokenize = rule[:tokenize] || false
  end

  def debug(s)
    Rails.logger.debug("Search::OnName::Predicate - #{s}")
  end

  def inspect
    "Search::OnName::Predicate: canon_field: #{@canon_field}"
  end

  def apply_rule(rule)
    apply_rule_part_1(rule)
    apply_rule_part_2(rule)
  end

  def apply_rule_part_1(rule)
    @scope_ = rule[:scope_] || ""
    @trailing_wildcard = rule[:trailing_wildcard] || false
    @leading_wildcard = rule[:leading_wildcard] || false
  end

  def apply_rule_part_2(rule)
    @wildcard_embedded_spaces = rule[:wildcard_embedded_spaces] || false
    @multiple_values = rule[:multiple_values] || false
    @predicate = build_predicate(rule)
    @allow_common_and_cultivar = rule[:allow_common_and_cultivar] || false
  end

  def apply_scope
    @has_scope = @scope_.present?
    @value_frequency = if @has_scope
                         1
                       else
                         @predicate.count("?")
                       end
  end

  def process_value
    @processed_value = @canon_value
    @processed_value = "%#{@processed_value}" if @leading_wildcard
    @processed_value = "#{@processed_value}%" if @trailing_wildcard
    return unless @wildcard_embedded_spaces
    @processed_value = @processed_value.gsub(/  */, "%").to_s
  end

  def build_predicate(rule)
    debug("build_predicate")
    if @multiple_values && @value.split(/,/).size > 1
      rule[:multiple_values_where_clause]
    else
      rule[:where_clause]
    end
  end

  def build_canon_value(val)
    if @multiple_values && @value.split(/,/).size > 1
      val.split(",").collect(&:strip)
    else
      val.tr("*", "%")
    end
  end

  def build_canon_field(field)
    if Search::OnName::FieldRule::RULES.key?(field)
      field
    elsif Search::OnName::FieldRule::RULES.key?(
      Search::OnName::FieldAbbrev::ABBREVS[field]
    )
      Search::OnName::FieldAbbrev::ABBREVS[field]
    else
      raise "Cannot search name for: #{field}."
    end
  end
end
