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
class Search::OnAuthor::WhereClauses
  attr_reader :sql

  def initialize(parsed_request, incoming_sql)
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def debug(s)
    Rails.logger.debug("Search::OnAuthor::WhereClause - #{s}")
  end

  def build_sql
    debug("Search::OnAuthor::WhereClause.sql")
    remaining_string = @parsed_request.where_arguments.downcase
    @common_and_cultivar_included = @parsed_request.common_and_cultivar
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    x = 0
    until remaining_string.blank?
      field, value, remaining_string = Search::NextCriterion.new(remaining_string).get
      Rails.logger.info("field: #{field}; value: #{value}")
      add_clause(field, value)
      x += 1
      fail "endless loop #{x}" if x > 50
    end
  end

  def add_clause(field, value)
    if field.blank? && value.blank?
      @sql
    elsif field.blank?
      # @sql = @sql.lower_name_like("*#{value.downcase}*")
      @sql = tokenize_2(@sql, "name-or-abbrev:", value)
    else
      # we have a field
      canonical_field = canon_field(field)
      canonical_value = value.blank? ? "" : canon_value(value)
      if ALLOWS_MULTIPLE_VALUES.key?(canonical_field) && canonical_value.split(/,/).size > 1
        case canonical_field
        when /\Aid:\z/
          @sql = @sql.where("id in (?)", canonical_value.split(",").collect(&:strip))
        when /\Aids:\z/
          @sql = @sql.where("id in (?)", canonical_value.split(",").collect(&:strip))
        when /\Aname-rank:\z/
          @sql = @sql.where("name_rank_id in (select id from name_rank where lower(name) in (?))", canonical_value.split(",").collect(&:strip))
        else
          fail "The field '#{field}' currently cannot handle multiple values separated by commas."
        end
      elsif WHERE_ASSERTION_HASH.key?(canonical_field)
        @sql = @sql.where(WHERE_ASSERTION_HASH[canonical_field])
      elsif FIELD_NEEDS_WILDCARDS.key?(canonical_field)
        @sql = @sql.where(FIELD_NEEDS_WILDCARDS[canonical_field], "%#{canonical_value}%")
      elsif TOKENIZE.key?(canonical_field)
        @sql = tokenize(@sql, canonical_field, canonical_value)
      elsif TOKENIZE_2.key?(canonical_field)
        @sql = tokenize_2(@sql, canonical_field, canonical_value)
      elsif WHERE_INTEGER_VALUE_HASH.key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH[canonical_field], canonical_value.to_i)
      else
        fail "No way to handle field: '#{canonical_field}' in an author search." unless WHERE_VALUE_HASH.key?(canonical_field)
        @sql = @sql.where(WHERE_VALUE_HASH[canonical_field], canonical_value)
      end
    end
  end

  def tokenize(sql, field, search_string)
    debug("tokenizing: field: #{field}")
    clause = TOKENIZE[field]
    debug("tokenizing: clause: #{clause}")
    search_string.gsub(/\*/, "%").gsub(/%+/, " ").split.each do |term|
      sql = sql.where(clause, "%#{term}%")
    end
    sql
  end

  def tokenize_2(sql, field, search_string)
    debug("tokenizing: field: #{field}")
    clause = TOKENIZE_2[field]
    debug("tokenizing: clause: #{clause}")
    search_string.gsub(/\*/, "%").gsub(/%+/, " ").split.each do |term|
      sql = sql.where(clause, "%#{term}%", "%#{term}%")
    end
    sql
  end

  def canon_value(value)
    value.gsub(/\*/, "%")
  end

  def canon_field(field)
    if WHERE_INTEGER_VALUE_HASH.key?(field)
      field
    elsif WHERE_ASSERTION_HASH.key?(field)
      field
    elsif FIELD_NEEDS_WILDCARDS.key?(field)
      field
    elsif TOKENIZE.key?(field)
      field
    elsif TOKENIZE_2.key?(field)
      field
    elsif WHERE_VALUE_HASH.key?(field)
      field
    elsif CANONICAL_FIELD_NAMES.value?(field)
      field
    elsif CANONICAL_FIELD_NAMES.key?(field)
      CANONICAL_FIELD_NAMES[field]
    else
      fail "Cannot search authors for: #{field}" unless CANONICAL_FIELD_NAMES.key?(field)
    end
  end

  WHERE_INTEGER_VALUE_HASH = {
    "id:" => "id = ? ",
    "ids:" => " id = ?",
    "duplicate-of-id:" => "duplicate_of_id = ? ",
  }

  WHERE_ASSERTION_HASH = {
    "is-a-duplicate:" => " duplicate_of_id is not null",
    "is-not-a-duplicate:" => " duplicate_of_id is null",
    "has-abbrev:" => " abbrev is not null",
    "has-no-abbrev:" => " abbrev is null",
    "has-name:" => " name is not null",
    "has-no-name:" => " name is null",
  }

  FIELD_NEEDS_WILDCARDS = {
    "notes:" => " lower(notes) like ? ",
    "comments:" => " exists (select null from comment where comment.author_id = author.id and comment.text like ?) ",
    "full-name:" => "lower(full_name) like ?",
  }

  TOKENIZE = {
    "name:" => " lower(f_unaccent(name)) like f_unaccent(?) ",
    "abbrev:" => " lower(f_unaccent(abbrev)) like f_unaccent(?) ",
  }

  TOKENIZE_2 = {
    "name-or-abbrev:" => "lower(f_unaccent(name)) like f_unaccent(?) or lower(f_unaccent(abbrev)) like f_unaccent(?) ",
  }

  WHERE_VALUE_HASH = {
    "name-exact:" => "lower(name) like ?",
    "abbrev-exact:" => "lower(abbrev) like ?",
    "full-name-exact:" => "lower(full_name) like ?",
    "comments-exact:" => " exists (select null from comment where comment.author_id = author.id and comment.text like ?) ",
    "comments-by:" => " exists (select null from comment where comment.author_id = author.id and comment.created_by like ?) ",
    "notes-exact:" => " lower(notes) like ? ",
    "ipni-id:" => "lower(ipni_id) like ?",
  }

  CANONICAL_FIELD_NAMES = {
    "n:" => "name:",
    "a:" => "abbrev:",
    "extra-name-text:" => "full_name:",
  }

  ALLOWS_MULTIPLE_VALUES = {
    "id:" => true,
    "ids:" => true,
  }
end
