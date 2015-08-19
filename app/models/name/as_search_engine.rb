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
class Name::AsSearchEngine < Name

  def self.search(raw, limit = 100, just_count_them = false, exclude_common_and_cultivar = true, apply_limit = true)
    logger.debug(%Q(\nName search: "#{raw}" up to #{limit} records; exclude_common_and_cultivar: #{exclude_common_and_cultivar}.))
    search_limit = limit
    search_string = raw
    rejected_pairings = []
    info = [%Q(Name search: "#{raw}"; )]
    id_search = Name.id_search?(search_string)
    exclude_common_and_cultivar = false if id_search
    if search_string.blank?
      results = []
    elsif search_string.gsub(/[^:]/,'').length == 0   # simple search because no field descriptors
      logger.debug("Simple search")
      info.push(apply_limit ? %Q( for up to #{limit} records) : %Q( for all records) )
      if exclude_common_and_cultivar
        info.push '; excluding common and cultivar' if exclude_common_and_cultivar
      else
        info.push '; including common and cultivar'
      end
      search_term = self.prepare_search_term_string(search_string).gsub(/\*/,'%').gsub(/ /,'%')
      rejected_pairings = []
      if just_count_them
        logger.debug('simple count')
        count = Name.not_common_or_cultivar.where([" (lower(full_name) like ?) ", search_term]).count
      else
        results = Name.includes(:name_status) \
            .includes(:name_tags) \
            .full_name_like(search_term) \
            .order(DEFAULT_ORDER_BY)
        results = results.not_common_or_cultivar if exclude_common_and_cultivar
        results = results.limit(search_limit) if apply_limit
        results = results.all
      end
    else # advanced search
      logger.debug("Advanced search")
      if rejected_pairings.blank?
        logger.debug("About to parse fields in search_string: #{search_string}")
        where,binds,rejected_pairings = Name.generic_bindings_to_where(self,format_search_terms(Name::DEFAULT_DESCRIPTOR,search_string))
        where,binds,rejected_pairings = Name::AsSearchEngine.bindings_to_where(rejected_pairings,where,binds)
        order_by_binds,rejected_pairings = Name.generic_bindings_to_order_by(rejected_pairings,LEGAL_TO_ORDER_BY)
        order_by_binds.push(DEFAULT_ORDER_BY)
      end
      if rejected_pairings.size > 0
        results = []
      else
        if just_count_them
          count = Name.where(binds.unshift(where)).count
        else
          results = Name.includes(:name_status).includes(:name_tags).where(binds.unshift(where)).order(order_by_binds).limit(search_limit).all
          results = results.not_common_or_cultivar if exclude_common_and_cultivar
          results = results.limit(search_limit) if apply_limit
          if apply_limit
            if limit == 1
              info.push "for up to 1 record"
            else
              info.push "for up to #{limit} record(s)"
            end
          else
            info.push "for all records"
          end
        end
        if exclude_common_and_cultivar
          info.push '; excluding common and cultivar'
          search_string += ' not-nt:common '
          search_string += ' not-nt:cultivar '
        else
          if id_search
            info.push '; including common and cultivar (ID search)'
          else
            info.push '; including common and cultivar'
          end
        end
      end
    end
    focus_anchor_id = 1 #results.size > 0 ? results.first.anchor_id : nil
    if just_count_them
      logger.debug('Counting')
      return count
    else
      logger.debug('Searching')
      return results, rejected_pairings,results.size == search_limit,focus_anchor_id,info
    end
  end

  # This turns field descriptors into parts of a where clause.
  # It is for "specific" field descriptors.  The "generic" field descriptors should have been consumed beforehand.
  def self.bindings_to_where(search_terms_array,where,binds)
    logger.debug("Name bindings_to_where: #{search_terms_array}")
    rejected_pairings = []
    search_terms_array.each do | pairing |
      logger.debug "pairing: #{pairing} with size: #{pairing.class}"
      if pairing.class == Array and pairing.size == 2
        case pairing[0].downcase
          when 'with-comments'
            where += " and exists (select null from comment where comment.name_id = name.id and comment.text like ?) "
            binds.push(prepare_search_term_string(pairing[1]))
          when 'with-comments-by'
            where += " and exists (select null from comment where comment.name_id = name.id and (lower(comment.created_by) like ? or lower(comment.updated_by) like ?)) "
            binds.push(prepare_search_term_string(pairing[1]))
            binds.push(prepare_search_term_string(pairing[1]))
          when 'with-comments-but-no-instances'
            where += " and exists (select null from comment where comment.name_id = name.id and comment.text like ?) and not exists (select null from instance where name_id = name.id)"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'with-author'
            where += " and exists (select null from author where name.author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'na'
            where += " and exists (select null from author where name.author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'a'
            where += " and exists (select null from author where name.author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'a-id'
            where += " and author_id = ? "
            binds.push(pairing[1].to_i)
          when 'ea-id'
            where += " and ex_author_id = ? "
            binds.push(pairing[1].to_i)
          when 'ba-id'
            where += " and base_author_id = ? "
            binds.push(pairing[1].to_i)
          when 'eba-id'
            where += " and ex_base_author_id = ? "
            binds.push(pairing[1].to_i)
          when 'sa-id'
            where += " and sanctioning_author_id = ? "
            binds.push(pairing[1].to_i)
          when 'hours-since-created'
            where += " and created_at > now() - interval '? hour' "
            binds.push(pairing[1].to_i)
          when 'hours-since-updated'
            where += " and updated_at > now() - interval '? hour' "
            binds.push(pairing[1].to_i)
          when 'duplicate-of'
            where += " and duplicate_of_id = ? "
            binds.push(pairing[1].to_i)
          when 'ba'
            where += " and exists (select null from author where name.base_author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'ea'
            where += " and exists (select null from author where name.ex_author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'eba'
            where += " and exists (select null from author where name.ex_base_author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'n'
            where += " and lower(full_name) like ? "
            binds.push(prepare_search_term_string(pairing[1]))
          when 'fn'
            where += " and lower(full_name) like ? "
            binds.push(prepare_search_term_string(pairing[1]))
          when 'sn'
            where += " and lower(simple_name) like ? "
            binds.push(prepare_search_term_string(pairing[1]))
          when 'ne'
            where += " and lower(name_element) like ? "
            binds.push(prepare_search_term_string(pairing[1]))
          when 'nt'
            where += " and name_type_id in (select id from name_type nt where lower(nt.name) like ?) "
            binds.push(pairing[1].downcase)
          when 'not-nt'
            where += " and ( name_type_id is null or name_type_id not in (select id from name_type nt where lower(nt.name) like ?) ) "
            binds.push(pairing[1].downcase + '%')
          when 'nr'
            where += " and name_rank_id in (select id from name_rank nr where lower(nr.name) like ?) "
            binds.push(pairing[1].downcase + '%')
          when 'ns'
            where += " and name_status_id in (select id from name_status ns where lower(ns.name) like ?) "
            binds.push(pairing[1].downcase)
          when 'sa'
            where += " and exists (select null from author where name.sanctioning_author_id = author.id and lower(author.name) like ? )"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'with-tag'
            where += " and exists (select null from name_tag_name where name.id = name_tag_name.name_id and exists (select null from name_tag where lower(name_tag.name) like ? and name_tag_name.tag_id = name_tag.id))"
            binds.push(prepare_search_term_string(pairing[1]))
          when 'parent-id'
            where += " and parent_id = ? "
            binds.push(pairing[1].to_i)
          else
            logger.error('no match')
            rejected_pairings.push(pairing.join(':'))
            logger.error "Rejected pairing: #{pairing}"
        end
      elsif pairing.class == String
        logger.debug('pairing.class is a String')
        case pairing.downcase
          when 'with-comments'
            where += " and exists (select null from comment where comment.name_id = name.id) "
          when 'with-comments-but-no-instances'
            where += " and exists (select null from comment where comment.name_id = name.id) and not exists (select null from instance where name_id = name.id)"
          when 'orth-var-but-no-orth-var-instances' 
            #where += " and name_status_id in (select id from name_status ns where lower(ns.name) = 'orth. var.') and not exists (select null from instance where name_id = name.id and instance_type_id in (select id from instance_type where instance_type.name = 'orthographic variant') "
            where += " and name_status_id in (select id from name_status ns where lower(ns.name) = 'orth. var.') "
            where += " and not exists (select null from instance i where i.name_id = name.id and i.instance_type_id in (select id from instance_type where instance_type.name = 'orthographic variant')) "
          when 'is-a-duplicate'
            where += " and duplicate_of_id is not null "
          else
            logger.error('no match')
            rejected_pairings.push(pairing)
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

