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
class Author::AsSearchEngine < Author

  def self.search(raw, limit = 100, just_count_them = false, exclude_common_and_cultivar = true, apply_limit=true)
    logger.debug(%Q(Author search for : "#{raw}" for up to #{limit} records; exclude_common_and_cultivar: #{exclude_common_and_cultivar}.))
    search_limit = limit
    search_string = raw
    info = [%Q(Author search: "#{raw}")]
    if search_string.blank?
      results = []
      rejected_pairings = []
    elsif raw.match('duplicate-abbrevs')
      results = Author.where(" abbrev is not null and abbrev in (select abbrev from author a2 group by a2.abbrev having count(*) > 1) ").order(" abbrev ")
      rejected_pairings = []
      info = [%Q(Author search for all records with duplicate abbreviations. [ * ignores search field])]
    elsif Author.search_is_simple?(raw)
      rejected_pairings = []
      results = Author.where(["lower(f_unaccent(name)) like f_unaccent(?) or lower(f_unaccent(abbrev)) like f_unaccent(?) ",
                              Author.prepare_search_term_string(search_string),
                              Author.prepare_search_term_string(search_string)]).\
                       order('name').limit(search_limit)
      if apply_limit
        results = results.limit(search_limit) 
        if limit == 1
          info.push " for up to 1 record"
        else
          info.push " for up to #{limit} records"
        end
      else
        info.push " for all records"
      end
    else
      where,binds,rejected_pairings = Author.generic_bindings_to_where(self,format_search_terms(DEFAULT_DESCRIPTOR,search_string))  
      where,binds,rejected_pairings = Author::AsSearchEngine.bindings_to_where(rejected_pairings,where,binds)
      order_by_binds,rejected_pairings = Author.generic_bindings_to_order_by(rejected_pairings,LEGAL_TO_ORDER_BY) 
      order_by_binds.push(DEFAULT_ORDER_BY)
      if rejected_pairings.size > 0
        results = []
      else
        results = Author.where(binds.unshift(where)).order(order_by_binds).limit(search_limit)
        results = results.limit(search_limit) if apply_limit
        if apply_limit
            if limit == 1
              info.push " for up to 1 record"
            else
              info.push " for up to #{limit} record(s)"
            end
        else
          info.push " for all records"
        end
      end      
    end
    focus_anchor_id = results.size > 0 ? results.first.anchor_id : nil
    return results, rejected_pairings,results.size == search_limit,focus_anchor_id,info
  end

  # This turns field descriptors into parts of a where clause.
  # It is for "specific" field descriptors.  The "generic" field descriptors should have been consumed beforehand.
  def self.bindings_to_where(search_terms_array,where,binds)
    logger.debug("bindings_to_where: #{search_terms_array}")
    rejected_pairings = []
    search_terms_array.each do | pairing |
      logger.debug "pairing: #{pairing}"
      logger.debug "pairing class: #{pairing.class}"
      logger.debug "pairing size: #{pairing.size}"
      if pairing.class == String         
        case pairing.downcase
        when 'with-comments'
          where += " and exists (select null from comment where comment.author_id = author.id) "
        else
          logger.error('No match on string pairing.')
          rejected_pairings.push(pairing)
          logger.error "Rejected pairing: #{pairing}"
        end
      elsif pairing.size == 2         
        case pairing[0].downcase
        when 'a'
          logger.debug('abbrev search')
          where += " and lower(f_unaccent(abbrev)) like f_unaccent(?) "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'n'
          logger.debug('name search')
          where += " and lower(f_unaccent(name)) like f_unaccent(?) "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'd'
          where += " and duplicate = upper(?) "
          binds.push(pairing[1])
        when 'with-comments'
          where += " and exists (select null from comment where comment.author_id = author.id and comment.text like ?) "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'with-comments-by'
          where += " and exists (select null from comment where comment.author_id = author.id and (lower(comment.created_by) like ? or lower(comment.updated_by) like ?)) "
          binds.push(prepare_search_term_string(pairing[1]))
          binds.push(prepare_search_term_string(pairing[1]))
        else
          logger.debug('no match')
          rejected_pairings.push("#{pairing.first}:#{pairing.last if pairing.size > 1}")
          logger.error "Rejected pairing: #{pairing}"
        end
      else
        # Most likely an empty search criterion.
        rejected_pairings.push([pairing])
        logger.error "Rejected pairing: #{pairing}"
      end
    end
    where.sub!(/\A *and/,'')
    return where,binds,rejected_pairings
  end

end

