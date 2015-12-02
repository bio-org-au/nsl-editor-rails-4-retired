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
class Search::OnReference::PredicateFieldRule

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
              :scope_

  DEFAULT_FIELD = 'citation:'

  def initialize(field,value)
    debug("initialize; field: #{field}; value: #{value}")
    @field = field
    @value = value
    @canon_field = build_canon_field(field)
    rule = RULES[@canon_field] || EMPTY_RULE
    @scope_ = rule[:scope_] || ''
    @has_scope = @scope_.present?
    @value = value
    @trailing_wildcard = rule[:trailing_wildcard] || false
    @leading_wildcard = rule[:leading_wildcard] || false
    @multiple_values = rule[:multiple_values] || false
    @canon_value = build_canon_value(value)
    @predicate = build_predicate(rule)
    if @has_scope
      @value_frequency = 1
    else
      @value_frequency = @predicate.count('?')
    end
    @processed_value = @canon_value
    @processed_value = "%#{@processed_value}" if @leading_wildcard
    @processed_value = "#{@processed_value}%" if @trailing_wildcard
    @tokenize = rule[:tokenize] || false
  end

  def debug(s)
    Rails.logger.debug("Search::OnReference::PredicateFieldRule - #{s}")
  end

  def inspect
    "Search::OnReference::PredicateFieldRule: canon_field: #{@canon_field}"
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
      val.split(',').collect {|v| v.strip}
    else
      val.gsub(/\*/,'%')
    end
  end

  def build_canon_field(field = DEFAULT_FIELD)
    if RULES.has_key?(field) 
      field
    elsif RULES.has_key?(ABBREVS[field])
      ABBREVS[field]
    else
      raise "Cannot search references for: #{field}." 
    end
  end

  ABBREVS = {
    'c:' => 'citation:',
    'cw:' => 'citation-wildcard:',
    't:' => 'title:',
    'ti:' => 'title:',
    'ty:' => 'type:',
    'ref-type:' => 'type:',
    'rt:' => 'type:',
    'a:' => 'author:',
    'y:' => 'year:',
    'pd:' => 'publication-date:',
    'is-duplicate:' => 'is-a-duplicate:',
    'duplicate:' => 'is-a-duplicate:',
  }

  RULES = {
    'is-a-duplicate:'       => {where_clause: " duplicate_of_id is not null"},
    'is-not-a-duplicate:'   => {where_clause: " duplicate_of_id is null"},
    'is-a-parent:'          => {where_clause: " exists (select null from reference child where child.parent_id = reference.id) "},
    'is-not-a-parent:'      => {where_clause: " not exists (select null from reference child where child.parent_id = reference.id) "},
    'has-no-children:'      => {where_clause: " not exists (select null from reference child where child.parent_id = reference.id) "},
    'has-no-parent:'        => {where_clause: " parent_id is null"},
    'is-a-child:'           => {where_clause: " parent_id is not null"},
    'is-not-a-child:'       => {where_clause: " parent_id is null"},
    'is-published:'         => {where_clause: " published"},
    'is-not-published:'     => {where_clause: " not published"},

    'author-exact:'         => {where_clause: " author_id in (select id from author where lower(name) like ?)"},
    'citation-exact:'       => {where_clause: " lower(citation) like ?"},
    'comments:'             => {where_clause: " exists (select null from comment where comment.reference_id = reference.id and comment.text like ?) "},
    'comments-by:'          => {where_clause: " exists (select null from comment where comment.reference_id = reference.id and comment.created_by like ?) "},
    'edition:'              => {where_clause: " lower(edition) like ?"},
    'publication-date:'     => {where_clause: " lower(publication_date) like ?"},
    'type:'                 => {multiple_values: true,
                                where_clause: " ref_type_id in (select id from ref_type where lower(name) like ?)",
                                multiple_values_where_clause: " ref_type_id in (select id from ref_type where lower(name) in (?))"},
    'author-role:'          => {where_clause: " ref_author_role_id in (select id from ref_author_role where lower(name) like ?)"},
    'title-exact:'          => {where_clause: " lower(title) like ?"},
    'isbn:'                 => {where_clause: " lower(isbn) like ?"},
    'issn:'                 => {where_clause: " lower(issn) like ?"},
    'published-location:'   => {where_clause: " lower(published_location) like ?"},
    'publisher:'            => {where_clause: " lower(publisher) like ?"},
    'volume:'               => {where_clause: " lower(volume) like ?"},
    'bhl:'                  => {where_clause: " lower(bhl_url) like ?"},
    'doi:'                  => {where_clause: " lower(doi) like ?"},
    'tl2:'                  => {where_clause: " lower(tl2) like ?"},

    'id:'                   => {multiple_values: true,
                                where_clause: " id = ? ",
                                multiple_values_where_clause: " id in (?)"},
    'ids:'                  => {multiple_values: true,
                                where_clause: " id = ? ",
                                multiple_values_where_clause: " id in (?)"},
    'author-id:'            => {multiple_values: true,
                                where_clause: " author_id = ? ",
                                multiple_values_where_clause: " id in (?)"},
    'year:'                 => {multiple_values: true,
                                where_clause: " year = ? ",
                                multiple_values_where_clause: " id in (?)"},
    'after-year:'           => {where_clause: " year > ? "},
    'before-year:'          => {where_clause: " year < ? "},
    'duplicate-of-id:'      => {multiple_values: true,
                                where_clause: " duplicate_of_id = ?",
                                multiple_values_where_clause: " duplicate_of_id in (?)"},

    'parent-id:'            => {where_clause: " id = ? or parent_id = ?"},
    'master-id:'            => {where_clause: " id = ? or duplicate_of_id = ?"},

    'citation:'             => {scope_: 'search_citation_text_for'},

    'citation-wildcard:'    => {trailing_wildcard: true, 
                                leading_wildcard: true, 
                                tokenize: true,
                                where_clause: " lower(citation) like ? "},

    'author:'               => {trailing_wildcard: true, 
                                leading_wildcard: true, 
                                where_clause: "author_id in (select id from author where lower(name) like ?)"},

    'comments:'             => {trailing_wildcard: true,
                                leading_wildcard: true, 
                                where_clause: " exists (select null from comment where comment.reference_id = reference.id and lower(comment.text) like ?) "},

    'title:'                => {trailing_wildcard: true, 
                                where_clause: " lower(title) like ? "},
  }
  

end


