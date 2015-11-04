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

  def initialize(parsed_request, incoming_sql)
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def build_sql
    Rails.logger.debug("Search::OnReference::WhereClause.sql")
    remaining_string = @parsed_request.where_arguments.downcase 
    @common_and_cultivar_included = @parsed_request.common_and_cultivar
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    x = 0 
    until remaining_string.blank?
      field,value,remaining_string = Search::NextCriterion.new(remaining_string).get 
      Rails.logger.debug("Search::OnReference::WhereClause.sql#build_sql; field: #{field}; value: #{value}")
      add_clause(field,value)
      x += 1
      raise "endless loop #{x}" if x > 50
    end
  end

  def add_clause(field,value)
    Rails.logger.debug("Search::OnReference::WhereClause.sql#add_clause; field: #{field}; value: #{value}")
    if field.blank? && value.blank?
      @sql
    elsif field.blank?
      @sql = @sql.lower_citation_like("*#{value.downcase}*")
    else 
      # we have a field
      canonical_field = canon_field(field)
      canonical_value = value.blank? ? '' : canon_value(value)
      if ALLOWS_MULTIPLE_VALUES.has_key?(canonical_field) && canonical_value.split(/,/).size > 1
        case canonical_field
        when /\Atype:\z/
          @sql = @sql.where("ref_type_id in (select id from ref_type where lower(name) in (?))",canonical_value.split(',').collect {|v| v.strip})
        else
          raise "The field '#{field}' currently cannot handle multiple values separated by commas." 
        end
      elsif canonical_field.match(/\Acomments-by:\z/)
        @sql = @sql.where("exists (select null from comment where comment.reference_id = reference.id and (lower(comment.created_by) like ? or lower(comment.updated_by) like ?))",
                          canonical_value,canonical_value)
      elsif WHERE_INTEGER_VALUE_HASH_TWICE.has_key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH_TWICE[canonical_field],canonical_value.to_i,canonical_value.to_i)
      elsif WHERE_INTEGER_VALUE_HASH.has_key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH[canonical_field],canonical_value.to_i||0)
      elsif WHERE_ASSERTION_HASH.has_key?(canonical_field)
        @sql = @sql.where(WHERE_ASSERTION_HASH[canonical_field])
      elsif FIELD_NEEDS_TRAILING_WILDCARD.has_key?(canonical_field)
        @sql = @sql.where(FIELD_NEEDS_TRAILING_WILDCARD[canonical_field],"#{canonical_value}%")
      elsif FIELD_NEEDS_WILDCARDS.has_key?(canonical_field)
        @sql = @sql.where(FIELD_NEEDS_WILDCARDS[canonical_field],"%#{canonical_value}%")
      else
        raise "No way to handle field: '#{canonical_field}' in a reference search." unless WHERE_VALUE_HASH.has_key?(canonical_field)
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
    elsif WHERE_INTEGER_VALUE_HASH_TWICE.has_key?(field)
      field
    elsif WHERE_VALUE_HASH.has_key?(field)
      field
    elsif FIELD_NEEDS_TRAILING_WILDCARD.has_key?(field)
      field
    elsif FIELD_NEEDS_WILDCARDS.has_key?(field)
      field
    elsif CANONICAL_FIELD_NAMES.has_value?(field)
      field
    elsif CANONICAL_FIELD_NAMES.has_key?(field)
      CANONICAL_FIELD_NAMES[field]
    else
      raise "Cannot search references for: #{field}." unless CANONICAL_FIELD_NAMES.has_key?(field)
    end
  end

  WHERE_INTEGER_VALUE_HASH = { 
    'id:' => "id = ? ",
    'author-id:' => "author_id = ? ",
    'year:' => "year = ? ",
    'after-year:' => "year > ? ",
    'before-year:' => "year < ? ",
  }

  WHERE_INTEGER_VALUE_HASH_TWICE = { 
    'parent-id:' => "id = ? or parent_id = ?"
  }
  
  FIELD_NEEDS_TRAILING_WILDCARD = { 
    'title:' => " lower(title) like ? ",
  }

  FIELD_NEEDS_WILDCARDS = { 
    'author:' => "author_id in (select id from author where lower(name) like ?)",
    'citation:' => " lower(citation) like ? ",
    'notes:' => " lower(notes) like ? ",
    'comments:' => " exists (select null from comment where comment.author_id = author.id and comment.text like ?) ",
  }

  WHERE_ASSERTION_HASH = { 
    'is-duplicate:' => " duplicate_of_id is not null",
    'is-a-duplicate:' => " duplicate_of_id is not null",
    'is-not-a-duplicate:' => " duplicate_of_id is null",
    'is-a-parent:' => " exists (select null from reference child where child.parent_id = reference.id) ",
    'is-not-a-parent:' => " not exists (select null from reference child where child.parent_id = reference.id) ",
    'has-no-children:' => " not exists (select null from reference child where child.parent_id = reference.id) ",
    'has-no-parent:' => " parent_id is null",
    'is-a-child:' => " parent_id is not null",
    'is-not-a-child:' => " parent_id is null",
    'is-published:' => " published",
    'is-not-published:' => " not published",
  }

  WHERE_VALUE_HASH = { 
    'author-exact:' => "author_id in (select id from author where lower(name) like ?)",
    'citation-exact:' => "lower(citation) like ?",
    'comments:' => " exists (select null from comment where comment.reference_id = reference.id and comment.text like ?) ",
    'comments-by:' => " exists (select null from comment where comment.reference_id = reference.id and comment.created_by like ?) ",
    'edition:' => "lower(edition) like ?",
    'notes-exact:' => "lower(notes) like ?",
    'publication_date:' => "lower(publication_date) like ?",
    'type:' => "ref_type_id in (select id from ref_type where lower(name) like ?)",
    'author_role:' => "ref_author_role_id in (select id from ref_author_role where lower(name) like ?)",
    'title-exact:' => "lower(title) like ?",
    'isbn:' => "lower(isbn) like ?",
    'issn:' => "lower(issn) like ?",
    'published_location:' => "lower(published_location) like ?",
    'publisher:' => "lower(publisher) like ?",
    'volume:' => "lower(volume) like ?",
    'bhl:' => "lower(bhl_url) like ?",
    'doi:' => "lower(doi) like ?",
    'tl2:' => "lower(tl2) like ?",
  }

  CANONICAL_FIELD_NAMES = {
    'c:' => 'citation:',
    't:' => 'title:',
    'ti:' => 'title:',
    'ty:' => 'type:',
    'ref-type:' => 'type:',
    'rt:' => 'type:',
    'a:' => 'author:',
    'y:' => 'year:',
    'ay:' => 'after-year:',
    'by:' => 'before-year:',
    'pd:' => 'publication_date:',
  }

  ALLOWS_MULTIPLE_VALUES = {
    'type:' => true
  }


end



