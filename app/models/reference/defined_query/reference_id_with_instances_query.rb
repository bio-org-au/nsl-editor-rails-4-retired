# frozen_string_literal: true
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
#   A defined query is one that the Search class knows about and may
#   instantiate.
class Reference::DefinedQuery::ReferenceIdWithInstancesQuery

    attr_reader :results,
              :limited,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :count,
              :show_csv,
              :total

  def initialize(parsed_request, sort_key = 'name')
    debug('start')
    run_query(parsed_request.where_arguments, parsed_request.limit.to_i, sort_key)
  end

  def debug(s)
    tag = "Reference::DefinedQuery::ReferenceIdWithInstancesQuery"
    Rails.logger.debug("#{tag}: #{s}")
  end

  # Query is "Instances for ref id"
  def run_query(search_string, limit = 100, order_by = "name",
                show_instances = true)
    debug("Start new ref_usages: search string: #{search_string};
                 show_instances: #{show_instances};
                 limit: #{limit}; order by: #{order_by}")
    reference_id = search_string.to_i
    @results = []
    # But what if that reference no longer exists?
    reference = Reference.find_by(id: reference_id)
    unless reference.blank?
      reference.display_as_part_of_concept
      @count = 1
      query = reference
              .instances
              .joins(:name)
              .includes(name: :name_status)
              .includes(:instance_type)
              .includes(this_is_cited_by: [:name, :instance_type])
      query = order_by == "page" ? query.ordered_by_page : query.ordered_by_name
      query.each do |instance|
        debug("Query loop.....")
        if @count < limit
          if instance.cited_by_id.blank?
            @count += 1
            if show_instances
              instance.display_within_reference
              @results.push(instance)
              instance.is_cited_by.each do |cited_by|
                @count += 1
                cited_by.expanded_instance_type = cited_by.instance_type.name
                @results.push(cited_by)
                if @count > limit
                  limited = true
                  break
                end
              end
              unless instance.cites_this.nil?
                @results.push(instance.cites_this)
                @count += 1
                if @count > limit
                  limited = true
                  break
                end
              end
            end
          end
        end
        if @count > limit
          limited = true
          break
        end
      end
      @results.unshift(reference)
    end
    @results
  end

end
