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
module AdvancedSearch
  SEARCH_LIMIT = 100
  GENERIC_LEGAL_TO_ORDER_BY = { "upd" => "updated_at", "cr" => "created_at" }

  def prepare_search_term_string(raw)
    # add_leading_wildcard(add_trailing_wildcard(raw.strip)).downcase.gsub(/\*/,'%')
    x = add_token_wildcards(raw.strip)
    x = add_trailing_wildcard(x)
    x.downcase.gsub(/\*/, "%")
  end

  # Allows for phrase match: double quotes toggle strict/wild
  def add_token_wildcards(raw)
    wild = true
    string = ""
    raw.split("").each do |c|
      if wild
        if c =~ / /
          string += "%"
        elsif c =~ /"/
          wild = !wild
        else
          string += c
        end
      else
        if c =~ /"/
          wild = !wild
        else
          string += c
        end
      end
    end
    string
  end

  def add_leading_wildcard(raw)
    if raw.match(/\A\^/)
      raw = raw.sub(/^./, "")
    else
      raw = "%" + raw
    end
  end

  def parse_search_for_limit(raw_search_request)
    supplied_limit = raw_search_request.to_s.gsub(/.*limit:([0-9][0-9]*)/, '\1').to_i
    calculated_limit = supplied_limit <= 0 ? SEARCH_LIMIT : supplied_limit
    [calculated_limit, raw_search_request.gsub(/limit:[^ ][^ ]*/, "")]
  end

  def add_trailing_wildcard(raw)
    if raw.match(/\$\Z/)
      # $ is anchor, so no wildcard and get rid of the $
      raw = raw.chop
    else
      raw += "%"
    end
  end

  def generic_bindings_to_where(_active_record_class, search_terms_array)
    logger.debug("generic_bindings_to_where: search_terms_array: #{search_terms_array.inspect}")
    where = ""
    binds = []
    rejected_pairings = []
    search_terms_array.each do |pairing|
      logger.debug "pairing: #{pairing}"
      if pairing.size == 2
        case pairing[0].downcase
        when "apni"
          where += " and source_id = ? "
          binds.push(pairing[1])
        when "cr-a"
          unless pairing[1].blank? || !pairing[1].gsub(/[0-9]/, "").blank?
            where += " and created_at >= ? "
            binds.push(Date.today.to_time - ((pairing[1].to_i - 1) * 86_400))
          end
        when "cr-b"
          unless pairing[1].blank? || !pairing[1].gsub(/[0-9]/, "").blank?
            where += " and created_at < ? "
            binds.push(Date.today.to_time - ((pairing[1].to_i - 1) * 86_400))
          end
        when "id"
          where += " and id = ? "
          binds.push(pairing[1].to_i)
        when "ids"
          # expecting args like: 'ids:23234,21231,213,'
          where += " and id in (#{(' ?,' * pairing[1].split(',').size).chop})"
          pairing[1].split(",").each { |p| binds.push(p.to_i) }
        when "upd-a"
          unless pairing[1].blank? || !pairing[1].gsub(/[0-9]/, "").blank?
            where += " and updated_at >= ? "
            binds.push(Date.today.to_time - ((pairing[1].to_i - 1) * 86_400))
          end
        when "upd-b"
          unless pairing[1].blank? || !pairing[1].gsub(/[0-9]/, "").blank?
            where += " and updated_at < ? "
            binds.push(Date.today.to_time - ((pairing[1].to_i - 1) * 86_400))
          end
        else
          logger.debug("no match")
          rejected_pairings.push(pairing)
          logger.debug("rejected_pairings: #{rejected_pairings.inspect}")
        end
      else
        rejected_pairings.push(pairing.join(":"))
        logger.error "Rejected pairing: #{pairing}"
      end
    end

    where.sub!(/\A *and/, "")
    [where, binds, rejected_pairings]
  end

  # This turns field descriptors into parts of an order by clause.
  # It is for "generic" field descriptors.
  def generic_bindings_to_order_by(search_terms_array, legal_to_order_by = {})
    logger.debug("generic_bindings_to_order_by: #{search_terms_array}")
    field_map = GENERIC_LEGAL_TO_ORDER_BY.merge(legal_to_order_by)
    order_by_binds = []
    rejected_pairings = []
    search_terms_array.each do |str|
      pairing = str.split(":")
      logger.debug "pairing: #{pairing}"
      if pairing.size == 2
        case pairing[0].downcase
        when "sort"
          order_by_argument = pairing[1] # e.g. "upd" or "upd d"  or "title"  or "title d"
          sort_component = order_by_argument
          order_by_argument.split(",").each do |sort_component|
            field_descriptor, sort_direction = interpret_sort_component(sort_component)
            field_name = field_map[field_descriptor]
            unless field_name.blank?
              order_by_binds.push("#{field_name} #{sort_direction}")
            end
          end
        else
          rejected_pairings.push(pairing)
          logger.error "Rejected pairing: #{pairing}"
        end
      else
        logger.error("Pairing should include exactly 2 elements, but does not. Rejecting pairing: #{pairing}")
        rejected_pairings.push(pairing)
      end
    end
    [order_by_binds, rejected_pairings]
  end

  def interpret_sort_component(component)
    if component.split.size == 1
      # assume ascending
      field_descriptor = component.split.first
      sort_direction = "asc"
    elsif component.split.size == 2
      # work out whether asc or desc
      field_descriptor = component.split.first
      sort_direction = case component.split[1].downcase
                       when "d" then "desc"
                       when "a" then "asc"
                       else "asc"
                        end
    else
      # 3 or more makes no sense
      field_descriptor = ""
      sort_direction = ""
    end
    [field_descriptor, sort_direction]
  end
end
