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

  def initialize(parsed_request, sort_key = "name")
    @parsed_request = parsed_request
    @search_string = parsed_request.where_arguments
    @sort_key = sort_key
    @limit = parsed_request.limit.to_i || 100
    @results = []
    run_query
    #           parsed_request.limit.to_i,
    #           sort_key)
  end

  def debug(s)
    tag = "Reference::DefinedQuery::ReferenceIdWithInstancesQuery"
    Rails.logger.debug("#{tag}: #{s}")
  end

  # Query is "Instances for ref id"
  def run_query
    find_reference
    find_instances unless @reference.blank?
  end

  def find_reference
    reference_id = @search_string.to_i
    @reference = Reference.find_by(id: reference_id)
  end

  def built_query
    query = @reference
            .instances
            .joins(:name)
            .includes(name: :name_status)
            .includes(:instance_type)
            .includes(this_is_cited_by: [:name, :instance_type])
    @sort_by == "page" ? query.ordered_by_page : query.ordered_by_name
  end

  def find_instances_for_ref
    built_query.each do |instance|
      if @count < @limit
        if instance.cited_by_id.blank?
          @count += 1
          include_standalone_instance(instance)
          include_synonym(instance) unless instance.cites_this.nil?
        end
      end
      break if @count > @limit
    end
  end

  def find_instances
    @reference.display_as_part_of_concept
    @count = 1
    find_instances_for_ref
    @results.unshift(@reference)
    @limited = true if @count > @limit
    @results
  end

  def include_standalone_instance(instance)
    instance.display_within_reference
    @results.push(instance)
    instance.is_cited_by.each do |cited_by|
      @count += 1
      cited_by.expanded_instance_type = cited_by.instance_type.name
      @results.push(cited_by)
    end
  end

  def include_synonym(instance)
    @results.push(instance.cites_this)
    @count += 1
  end
end
