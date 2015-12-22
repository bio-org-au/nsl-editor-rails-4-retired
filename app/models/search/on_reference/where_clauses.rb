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
class Search::OnReference::WhereClauses

  attr_reader  :sql

  DEFAULT_FIELD = 'citation-text:'

  def initialize(parsed_request, incoming_sql)
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def debug(s)
    Rails.logger.debug("Search::OnReference::WhereClause - #{s}")
  end

  def build_sql
    debug("build_sql")
    remaining_string = @parsed_request.where_arguments.downcase 
    @common_and_cultivar_included = @parsed_request.common_and_cultivar
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    x = 0 
    until remaining_string.blank?
      field,value,remaining_string = Search::NextCriterion.new(remaining_string).get 
      add_clause(field,value)
      x += 1
      raise "endless loop #{x}" if x > 50
    end
  end

  def add_clause(field,value)
    debug("add_clause for field: #{field}; value: #{value}")
    if field.blank? && value.blank?
      @sql
    else 
      field_or_default = field.blank? ? DEFAULT_FIELD : field
      debug("field_or_default: #{field_or_default}")
      rule = Search::OnReference::PredicateFieldRule.new(field_or_default,value)
      apply_rule(rule)
      apply_order(rule)
    end
  end

  def apply_rule(rule)
    if rule.tokenize
      apply_predicate_to_tokens(rule)
    elsif rule.has_scope
      #@sql = @sql.send(rule.scope_,rule.value).select("*")
      @sql = @sql.send(rule.scope_,rule.value)
      # https://github.com/rails/rails/issues/15138
      # Invalid SQL generated when using count with select values
      # @sql = @sql.send(rule.scope_,rule.value).select("ref_type_id,created_at,'thing' as citation_html")
      #.select("*,ts_headline('english'::regconfig,coalesce((citation)::text,''::text), plainto_tsquery('english', ''' ' || unaccent('hookers')|| ' ''' || ':*')) ")
    else
      apply_predicate(rule)
    end
  end

  def apply_predicate(rule)
    case rule.value_frequency
      when 0
        @sql = @sql.where(rule.predicate)
      when 1
        @sql = @sql.where(rule.predicate,rule.processed_value)
      when 2
        @sql = @sql.where(rule.predicate,rule.processed_value,rule.processed_value)
      when 3
        @sql = @sql.where(rule.predicate,rule.processed_value,rule.processed_value,rule.processed_value)
      else
        raise "Unexpected value frequency: #{rule.value_frequency}"
      end
  end

  def apply_predicate_to_tokens(rule)
    debug("apply_predicate_to_tokens: rule.predicate: #{rule.predicate}; rule.value: #{rule.value}")
    predicate = rule.predicate
    rule.value.gsub(/\*/,'%').gsub(/%+/,' ').split.each do |term|
      @sql = @sql.where(predicate,"%#{term}%")
    end
  end

  def apply_order(rule)
    if rule.order
      @sql = @sql.order(rule.order)
    else
      @sql = @sql.order('citation')
    end
  end
end


