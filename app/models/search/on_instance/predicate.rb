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
class Search::OnInstance::Predicate
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
              :join_name

  def initialize(field, value)
    @field = field
    @canon_field = build_canon_field(field)
    rule = Search::OnInstance::FieldRule::RULES[@canon_field] || EMPTY_RULE
    @value = value
    apply_rule(rule)
    @canon_value = build_canon_value
    apply_scope
    @order = rule[:order] || nil
    process_value
    @tokenize = rule[:tokenize] || false
    @join_name = rule[:join] == :name
  end

  def debug(s)
    Rails.logger.debug("Search::OnInstance::Predicate - #{s}")
  end

  def inspect
    "Search::OnInstance::Predicate: canon_field: #{@canon_field}"
  end

  def apply_rule(rule)
    @scope_ = rule[:scope_] || ""
    @trailing_wildcard = rule[:trailing_wildcard] || false
    @leading_wildcard = rule[:leading_wildcard] || false
    @multiple_values = rule[:multiple_values] || false
    @predicate = build_predicate(rule)
    # TODO: build this into the rule
    @value = @value.downcase unless @canon_field =~ /-match/
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
  end

  def build_predicate(rule)
    if @multiple_values && @value.split(/,/).size > 1
      rule[:multiple_values_where_clause]
    else
      rule[:where_clause]
    end
  end

  def build_canon_value
    if @multiple_values && @value.split(/,/).size > 1
      @value.split(",").collect(&:strip)
    else
      @value.tr("*", "%")
    end
  end

  def build_canon_field(field)
    if Search::OnInstance::FieldRule::RULES.key?(field)
      field
    elsif Search::OnInstance::FieldRule::RULES.key?(
      Search::OnInstance::FieldAbbrev::ABBREVS[field]
    )
      Search::OnInstance::FieldAbbrev::ABBREVS[field]
    else
      raise "Cannot search instances for: #{field}."
    end
  end
end
