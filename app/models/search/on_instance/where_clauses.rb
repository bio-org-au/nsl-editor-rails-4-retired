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
class Search::OnInstance::WhereClauses

  attr_reader  :sql

  def initialize(parsed_request, incoming_sql)
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def build_sql
    Rails.logger.debug("Search::OnInstance::WhereClause build_sql")
    remaining_string = @parsed_request.where_arguments.downcase 
    Rails.logger.debug("Search::OnInstance::WhereClause build_sql remaining_string: #{remaining_string}")
    @common_and_cultivar_included = @parsed_request.common_and_cultivar
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    x = 0 
    until remaining_string.blank?
      field,value,remaining_string = Search::NextCriterion.new(remaining_string).get 
      Rails.logger.debug("Search::OnInstance::WhereClause.sql#build_sql; field: #{field}; value: #{value}")
      add_clause(field,value)
      x += 1
      raise "endless loop #{x}" if x > 50
    end
  end

  def add_clause(field,value)
    Rails.logger.debug("Search::OnInstance::WhereClause add_clause field: #{field}; value: #{value}")
    if field.blank? && value.blank?
      @sql
    elsif field.blank? || field.match(/\Aname:\z/)
      # default field
      canonical_value = value.blank? ? '' : canon_value(value)
      @sql = @sql.where([' exists (select null from name where name.id = instance.name_id and lower(full_name) like ?)',"%#{canonical_value.gsub(/ /,'%')}%"])
    else 
      # we have a field
      canonical_field = canon_field(field)
      canonical_value = value.blank? ? '' : canon_value(value)
      if ALLOWS_MULTIPLE_VALUES.has_key?(canonical_field) && canonical_value.split(/,/).size > 1
        case canonical_field
        when /\Aid:\z/
          @sql = @sql.where("id in (?)",canonical_value.split(',').collect {|v| v.strip})
        when /\Aids:\z/
          @sql = @sql.where("id in (?)",canonical_value.split(',').collect {|v| v.strip})
        when /\Atype:\z/
          @sql = @sql.where("exists (select null from instance_type where instance_type_id = instance_type.id and instance_type.name in (?))",canonical_value.split(',').collect {|v| v.strip})
        else
          raise "The field '#{field}' currently cannot handle multiple values separated by commas." 
        end
      elsif WHERE_INTEGER_VALUE_HASH.has_key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH[canonical_field],canonical_value.to_i)
      elsif WHERE_ASSERTION_HASH.has_key?(canonical_field)
        @sql = @sql.where(WHERE_ASSERTION_HASH[canonical_field])
      elsif FIELD_NEEDS_WILDCARDS.has_key?(canonical_field)
        @sql = @sql.where(FIELD_NEEDS_WILDCARDS[canonical_field],"%#{canonical_value.gsub(/ /,'%')}%")
      else
        Rails.logger.error("Search::OnInstance::WhereClause add_clause - out of options")
        raise "No way to handle field: '#{canonical_field}' in an instance search." unless WHERE_VALUE_HASH.has_key?(canonical_field)
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
    elsif WHERE_ASSERTION_HASH.has_key?(field)
      field
    elsif FIELD_NEEDS_WILDCARDS.has_key?(field)
      field
    elsif ALLOWS_MULTIPLE_VALUES.has_key?(field)
      field
    elsif WHERE_VALUE_HASH.has_key?(field)
      field
    elsif CANONICAL_FIELD_NAMES.has_value?(field)
      field
    elsif CANONICAL_FIELD_NAMES.has_key?(field)
      CANONICAL_FIELD_NAMES[field]
    else
      raise "Cannot search instances for: #{field}." unless CANONICAL_FIELD_NAMES.has_key?(field)
    end
  end

  WHERE_INTEGER_VALUE_HASH = { 
    'id:' => "id = ? "
  }

  WHERE_VALUE_HASH = { 
    'name:' => "lower(name) like ?",
    'type:' => " exists (select null from instance_type where instance_type_id = instance_type.id and instance_type.name like ?) ",
    'comments:' => " exists (select null from comment where comment.instance_id = instance.id and comment.text like ?) ",
    'comments-by:' => " exists (select null from comment where comment.instance_id = instance.id and comment.created_by like ?) ",
    'page:' => " lower(page) like ?",
    'page-qualifier:' => " lower(page_qualifier) like ?",
    'note-key:' => " exists (select null from instance_note where instance_id = instance.id and exists (select null from instance_note_key where instance_note_key_id = instance_note_key.id and lower(instance_note_key.name) like ?)) ",
    'notes-exact:' => " exists (select null from instance_note where instance_id = instance.id and lower(instance_note.value) like ?) ",
    'verbatim-name-exact:' => "lower(verbatim_name_string) like ?",
  }
  FIELD_NEEDS_WILDCARDS = { 
    'verbatim-name:' => "lower(verbatim_name_string) like ?",
    'notes:' => " exists (select null from instance_note where instance_id = instance.id and lower(instance_note.value) like ?) ",
  }

  #FIELD_NEEDS_WILDCARDS = { 
  #  'name:' => "author_id in (select id from author where lower(name) like ?)",
  #}

  CANONICAL_FIELD_NAMES = {
    'n:' => 'name:',
    'a:' => 'abbrev:',
    'adnot:' => 'comments:',
    'adnot-by:' => 'comments-by:',
    'type:' => 'instance-type:',
    't:' => 'instance-type:',
    'p:' => 'page:',
    'pq:' => 'page-qualifier:',
    'note:' => 'notes:',
    'note-exact:' => 'notes-exact:',
  }

  ALLOWS_MULTIPLE_VALUES = {
    'ids:' => " id in (?)",
    'id:' => " id in (?)",
    'type:' => " exists (select null from instance_type where instance_type_id = instance_type.id and instance_type.name in (?))",
  }

  WHERE_ASSERTION_HASH = { 
    'cites-an-instance:' => " cites_id is not null",
    'is-cited-by-an-instance:' => " cited_by_id is not null",
    'does-not-cite-an-instance:' => " cites_id is null",
    'is-not-cited-by-an-instance:' => " cited_by_id is null",
    'verbatim-name-matches-full-name:' => " lower(verbatim_name_string) = (select lower(full_name) from name where name.id = instance.name_id) ",
    'verbatim-name-does-not-match-full-name:' => " lower(verbatim_name_string) != (select lower(full_name) from name where name.id = instance.name_id) ",
  }

end



