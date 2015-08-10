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
class Name::AsTypeahead < Name
  
  def self.on_full_name(term)
    if term.blank?
      results = []
    elsif 
      results = Name.where(["lower(full_name) like ?",term.downcase+'%'])\
        .order('lower(full_name)').limit(SEARCH_LIMIT) \
        .collect {|n| {value: "#{n.full_name} - #{n.name_status.name}", id: n.id}} 
    end
    results
  end 
  
  # Offer parents of the appropriate rank:
  # - infra-species (below species)   : rank must be above the name's rank and equal to or below species rank
  # - species                         : any rank above species and equal to or below genus
  # - genus, above genus, below family: rank must be above the name's rank and equal to or below family
  # - family and above                : any rank above the name's rank
  # - [unranked]                      : [unranked] and any non-deprecated rank above [unranked]
  #
  # Exclude names marked as duplicates.
  # Show an instance count for each result.
  def self.name_parent_suggestions(term, avoid_id, rank_id)
    if term.blank? || rank_id.blank?
      results = []
    elsif 
      query = Name.not_a_duplicate.
                   full_name_like(term).
                   avoids_id(avoid_id.try('to_i')||-1).
                   joins(:name_status).
                   joins('left outer join instance on instance.name_id = name.id').
                   order_by_full_name.
                   limit(SEARCH_LIMIT)
      if rank_id != 'undefined' && NameRank.id_is_unranked?(rank_id.to_i)
        query = query.ranks_for_unranked
      else
        query = query.from_a_higher_rank(rank_id)
      end
      query = query.but_rank_not_too_high(rank_id).
                   select_fields_for_parent_typeahead.
                   group("name.id, name.full_name, name_rank.name, name_status.name").
                   collect {|n| {value: "#{n.full_name} | #{n.name_rank_name} | #{n.name_status_name} | #{ActionController::Base.helpers.pluralize(n.instance_count,'instance')} ", id: n.id}} 
      results = query
    end
    results
  end

  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.cultivar_parent_suggestions(term,avoid_id,rank_id = -1)
    logger.debug("cultivar_parent_suggestions term: #{term} avoiding: #{avoid_id} for rank: #{rank_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate.
                   full_name_like(term).
                   avoids_id(avoid_id.try('to_i') || -1).
                   joins(:name_rank).
                   joins(:name_status).
                   name_rank_not_deprecated.
                   name_rank_not_infra.
                   name_rank_not_na.
                   name_rank_not_unknown.
                   name_rank_genus_and_below.
                   select_fields_for_typeahead.
                   order_by_full_name.
                   limit(SEARCH_LIMIT)
      if rank_id != 'undefined' && NameRank.id_is_unranked?(rank_id.to_i)
        query = query.ranks_for_unranked_assumes_join
      else
        query = query.name_rank_not_unranked
      end
      query = query.collect {|n| {value: "#{n.full_name} | #{n.name_rank_name} ", id: n.id}}
      results = query
    end
    results
  end


  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.hybrid_parent_suggestions(term,avoid_id,rank_id = -1)
    logger.debug("hybrid_parent_suggestions term: #{term} avoiding: #{avoid_id} for rank: #{rank_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate.
                   full_name_like(term).
                   avoids_id(avoid_id.try('to_i') || -1).
                   joins(:name_rank).
                   joins(:name_status).
                   name_rank_not_deprecated.
                   name_rank_not_infra.
                   name_rank_not_na.
                   name_rank_not_unknown.
                   name_rank_species_and_below.
                   select_fields_for_typeahead.
                   order_by_full_name.
                   limit(SEARCH_LIMIT)
      if rank_id != 'undefined' && NameRank.id_is_unranked?(rank_id.to_i)
        query = query.ranks_for_unranked_assumes_join
      else
        query = query.name_rank_not_unranked
      end
      query = query.collect {|n| {value: "#{n.full_name} | #{n.name_rank_name}", id: n.id}}
      results = query
    end
    results
  end


  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.duplicate_suggestions(term, avoid_id)
    logger.debug("duplicate_suggestions for term: #{term}; avoiding: #{avoid_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate.
        full_name_like(term).
        avoids_id(avoid_id.to_i).
        joins(:name_rank).
        joins(:name_status).
        select_fields_for_typeahead.
        limit(SEARCH_LIMIT).
        order_by_full_name
      results = query.collect {|n| {value: "#{n.full_name} | #{n.name_status_name}", id: n.id}}
    end
    results
  end

end

