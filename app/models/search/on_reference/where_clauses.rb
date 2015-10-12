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

  def initialize(parsed_query, incoming_sql)
    @parsed_query = parsed_query
    @sql = incoming_sql
    build_sql
  end

  def build_sql
    Rails.logger.debug("Search::OnReference::WhereClause.sql")
    remaining_string = @parsed_query.where_arguments.downcase 
    @common_and_cultivar_included = @parsed_query.common_and_cultivar
    @sql = @sql.for_id(@parsed_query.id) if @parsed_query.id
    x = 0 
    until remaining_string.blank?
      field,value,remaining_string = Search::NextCriterion.new(remaining_string).get 
      Rails.logger.info("field: #{field}; value: #{value}")
      add_clause(field,value)
      x += 1
      raise "endless loop #{x}" if x > 50
    end
  end

  def add_clause(field,value)
    if field.blank? && value.blank?
      @sql
    elsif field.blank?
      @sql = @sql.lower_citation_like(value.downcase)
    elsif field.match(/\Acitation:\z/)
      @sql = @sql.lower_citation_like(value.downcase)
    else 
      # we have a field
      canonical_field = canon_field(field)
      canonical_value = value.blank? ? '' : canon_value(value)
      if ALLOWS_MULTIPLE_VALUES.has_key?(canonical_field) && canonical_value.split(/,/).size > 1
        case canonical_field
        when /\Aname-rank:\z/
          @sql = @sql.where("name_rank_id in (select id from name_rank where lower(name) in (?))",canonical_value.split(',').collect {|v| v.strip})
        when /\Aname-type:\z/
          @sql = @sql.where("name_type_id in (select id from name_type where lower(name) in (?))",canonical_value.split(',').collect {|v| v.strip})
        when /\Aname-status:\z/
          @sql = @sql.where("name_status_id in (select id from name_status where lower(name) in (?))",canonical_value.split(',').collect {|v| v.strip})
        else
          raise "The field '#{field}' currently cannot handle multiple values separated by commas." 
        end
      elsif canonical_field.match(/\Acomments-by:\z/)
        @sql = @sql.where("exists (select null from comment where comment.name_id = name.id and (lower(comment.created_by) like ? or lower(comment.updated_by) like ?))",
                          canonical_value,canonical_value)
      elsif WHERE_INTEGER_VALUE_HASH_TWICE.has_key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH_TWICE[canonical_field],canonical_value.to_i,canonical_value.to_i)
      elsif WHERE_INTEGER_VALUE_HASH.has_key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH[canonical_field],canonical_value.to_i)
      else
        raise 'No way to handle field.' unless WHERE_VALUE_HASH.has_key?(canonical_field)
        @sql = @sql.where(WHERE_VALUE_HASH[canonical_field],canonical_value)
      end
    end
  end

  def canon_value(value)
    value.gsub(/\*/,'%')
  end

  def canon_field(field)
    if WHERE_INTEGER_VALUE_HASH.has_key?(field)
      field
    elsif WHERE_INTEGER_VALUE_HASH_TWICE.has_key?(field)
      field
    elsif WHERE_VALUE_HASH.has_key?(field)
      field
    elsif CANONICAL_FIELD_NAMES.has_value?(field)
      field
    elsif CANONICAL_FIELD_NAMES.has_key?(field)
      CANONICAL_FIELD_NAMES[field]
    else
      raise "No such field: #{field}." unless CANONICAL_FIELD_NAMES.has_key?(field)
    end
  end

  WHERE_INTEGER_VALUE_HASH = { 
    'id:' => "id = ? "
  }

  WHERE_INTEGER_VALUE_HASH_TWICE = { 
    'parent-id:' => "id = ? or parent_id = ?"
  }

  WHERE_VALUE_HASH = { 
    'citation:' => "lower(citation) like ?)",
    'comments:' => " exists (select null from comment where comment.reference_id = reference.id and comment.text like ?) ",
    'comments-by:' => " exists (select null from comment where comment.reference_id = reference.id and comment.created_by like ?) ",
  }

  CANONICAL_FIELD_NAMES = {
    'c:' => 'citation:',
    't:' => 'title:',
    'a:' => 'author:'
  }

  ALLOWS_MULTIPLE_VALUES = {
    'name-type:' => true
  }


end



