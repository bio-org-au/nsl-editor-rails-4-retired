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

class Author::AsTypeahead < Author

  def self.on_abbrev(term)
    if term.blank?
      results = []
    elsif 
      results = Author.lower_abbrev_like(term+'%')\
        .where("duplicate_of_id is null")\
        .order('abbrev').limit(SEARCH_LIMIT)\
        .collect {|n| {value: "#{n.abbrev}", id: "#{n.id}"}} 
    end
    results
  end 

  # Collection of authors to be offered in a typeahead field based on a name fragment.
  # Also shows count of authored references.
  def self.on_name(term)
    if term.blank?
      results = []
    elsif 
      results = Author.lower_name_like(term+'%')\
        .joins('left outer join reference on reference.author_id = author.id')\
        .select('author.name as name, author.id as id, count(reference.id) as ref_count')\
        .group('lower(author.name),author.id')\
        .order('author.name').limit(SEARCH_LIMIT)\
        .collect {|n| {value: n.ref_count == 0 ? "#{n.name}" : "#{n.name} | #{n.ref_count} #{'ref'.pluralize(n.ref_count)}", id: "#{n.id}"}} 
    end
    results
  end 

  # Based on the on_name method, but also excludes :id passed in.
  # Used for offering duplicates_of records.
  def self.on_name_duplicate_of(term,excluded_id)
    if term.blank?
      results = []
    elsif 
      results = Author.lower_name_like(term+'%')\
        .where([" author.id <> ?",excluded_id])\
        .joins('left outer join reference on reference.author_id = author.id')\
        .select('author.name as name, author.id as id, count(reference.id) as ref_count')\
        .group('lower(author.name),author.id')\
        .order('author.name').limit(SEARCH_LIMIT)\
        .collect {|n| {value: n.ref_count == 0 ? "#{n.name}" : "#{n.name} | #{n.ref_count} #{'ref'.pluralize(n.ref_count)}", id: "#{n.id}"}} 
    end
    results
  end 

end

