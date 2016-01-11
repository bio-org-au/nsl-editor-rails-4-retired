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

class Reference::AsTypeahead < Reference
  # Tokenize search terms so word order is not important.
  # Recognise repeated search tokens
  # e.g. walsh in walsh should check for 2 walshes
  # Allow for an ID to exclude, but default it to a meaningless value so not necessary.
  def self.on_citation(terms, excluded_id = -1)
    where = ""
    binds = []
    terms = terms.gsub(/\*/, "%")
    terms_array = terms.split
    terms_uniq = terms_array.uniq
    terms_uniq.collect do |uniq_term|
      { value: uniq_term, freq: terms_array.count(uniq_term) }
    end.each do |hash|
      where += " lower(citation) like lower(?) and "
      search_term = "#{hash[:value]}%" * hash[:freq]
      binds.push "%#{search_term}"
    end
    where += " 1=1 "
    results = Reference.includes(:ref_type)
              .where.not(ref_type: { name: "Journal" })
              .not_duplicate
              .where.not(reference: { id: excluded_id })
              .where(binds.unshift(where))
              .order("citation")
              .limit(SEARCH_LIMIT)
              .collect { |ref| { value: "#{ref.citation} #{'[' + ref.pages + ']' unless ref.pages_useless?} #{' [' + ref.ref_type.name.downcase + ']'}", id: "#{ref.id}" } }
  end

  # Based on self.on_citation.
  # Tokenize search terms so word order is not important.
  # Recognise repeated search tokens
  # e.g. walsh in walsh should check for 2 walshes
  # Expect an ID to exclude.
  #
  # But also restricts to references of the same type or unknown type.
  def self.on_citation_for_duplicate(terms, current_id)
    where = ""
    binds = []
    terms = terms.gsub(/\*/, "%")
    terms_array = terms.split
    terms_uniq = terms_array.uniq
    terms_uniq.collect do |uniq_term|
      { value: uniq_term, freq: terms_array.count(uniq_term) }
    end.each do |hash|
      where += " lower(citation) like lower(?) and "
      search_term = "#{hash[:value]}%" * hash[:freq]
      binds.push "%#{search_term}"
    end
    where += " 1=1 "
    results = Reference.includes(:ref_type)
              .where.not(reference: { id: current_id })
              .not_duplicate
              .where(binds.unshift(where))
              .order("citation")
              .limit(SEARCH_LIMIT)
    unless Reference.find(current_id).ref_type.unknown?
      results = results.where(ref_type_id: [Reference.find(current_id).ref_type_id, RefType.unknown.id])
    end
    results.collect { |ref| { value: "#{ref.citation} | #{'[' + ref.pages + ']' unless ref.pages_useless?} #{' [' + ref.ref_type.name.downcase + ']'}", id: "#{ref.id}" } }
  end

  # Based on self.on_citation_for_duplicate.
  # Tokenize search terms so word order is not important.
  # Recognise repeated search tokens
  # e.g. walsh in walsh should check for 2 walshes
  # Expect an ID to exclude.
  # Restricts to references to legal types based on rules in ref_type i.e. which parent ref types are allowed, if any.
  # Accepts a ref type id param - the one on screen - rather than looking at the saved record.
  def self.on_citation_for_parent(terms, current_id, p_ref_type_id)
    Rails.logger.debug("on_citation_for_parent with ref_type_id: #{p_ref_type_id}; #{p_ref_type_id.to_i}")
    if p_ref_type_id.present?
      best_ref_type_id = p_ref_type_id
    else
      best_ref_type_id = Reference.find(current_id).ref_type_id
    end
    where = ""
    binds = []
    terms = terms.gsub(/\*/, "%")
    terms_array = terms.split
    terms_uniq = terms_array.uniq
    terms_uniq.collect do |uniq_term|
      { value: uniq_term, freq: terms_array.count(uniq_term) }
    end.each do |hash|
      where += " lower(citation) like lower(?) and "
      search_term = "#{hash[:value]}%" * hash[:freq]
      binds.push "%#{search_term}"
    end
    where += " 1=1 "
    results = Reference.joins(:ref_type).includes(:ref_type)
              .where.not(reference: { id: current_id })
              .not_duplicate
              .where(binds.unshift(where))
              .where(ref_type_id: RefType.find(best_ref_type_id).parent_id)
              .order("citation")
              .limit(SEARCH_LIMIT)
    results.collect { |ref| { value: "#{ref.citation} | #{'[' + ref.pages + ']' unless ref.pages_useless?} #{' [' + ref.ref_type.name.downcase + ']'}", id: "#{ref.id}" } }
  end
end
