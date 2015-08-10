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
class Instance::AsSearchEngine < Instance

  # Instances of a name algorithm: work on a single name starts here.
  def self.name_usages(name_id)
    logger.debug("======================================")
    logger.debug("Instance::AsSearchEngine.name_usages: #{name_id}")
    logger.debug("======================================")
    results = []
    rejected_pairings = []
    names = Name.where(id: name_id)
    unless names.blank?
      name = names.first
      if name.apc? # triggers service call
        show_apc = true
        apc_instance_id = name.apc_instance_id
      else
        show_apc = false
      end 
      name.display_as_part_of_concept
      already_shown = []
      name.instances.sort do |i1,i2| 
        [i1.reference.year||9998,i1.order_within_year,i1.reference.author.try('name')||'x'] <=> [i2.reference.year||9999, i2.order_within_year,i2.reference.author.try('name')||'y'] 
      end.each do |instance|
        if instance.simple? # simple instance
          Instance.show_simple_instance_under_searched_for_name(instance).each do |one_instance|
            one_instance.show_primary_instance_type = true
            one_instance.show_apc_tick = (one_instance.id == name.apc_instance_id)
            one_instance.consider_for_apc_tick = true
            results.push(one_instance)
          end
        else # relationship instance
          citing_instance = instance.this_is_cited_by
          unless already_shown.include?(citing_instance.id)
            Instance::AsSearchEngine.show_relationship_instance_under_searched_for_name(name,citing_instance).each do |element|
              element.consider_for_apc_tick = false
              results.push(element)
            end
            already_shown.push(citing_instance.id)
          end
        end
      end
      results.unshift(name)
    end
    results
  end

  # NSL-536: If instance name is not the subject name then do not show the instance type.
  def self.show_relationship_instance_under_searched_for_name(name,instance)
    logger.debug("Instance::AsSearchEngine.show_relationship_instance_under_searched_for_name: name: #{name.id} #{name.full_name}, instance: #{instance.id}")
    results = []
    instance.display_as_citing_instance_within_name_search
    results.push(instance)
    Instance.find_by_sql("select i.* " + 
                         "  from instance i" +  
                         "  inner join instance_type t " + 
                         "        on i.instance_type_id = t.id " +
                         " where i.cited_by_id = #{instance.id} " +
                         " order by case t.name " +
                         "          when 'basionym' then 1 " +
                         "          when 'common name' then 99 " +
                         "          when 'vernacular name' then 99 " +
                         "          else 2 end, " +
                         "          case nomenclatural " +
                         "          when true then 1 " +
                         "          else 2 end, " +
                         "          case taxonomic " +
                         "          when true then 2 " +
                         "          else 1 end").each do |cited_by_original_instance|
      logger.debug("cited_by_original_instance: #{cited_by_original_instance.id}; type: #{cited_by_original_instance.instance_type.name}")
      if cited_by_original_instance.name.id == name.id
        logger.debug("cited_by_original_instance.name.id == name.id")
        cited_by_original_instance.expanded_instance_type = cited_by_original_instance.instance_type.name
        if cited_by_original_instance.misapplied?
          cited_by_original_instance.display_as = 'cited-by-relationship-instance'
        else
          cited_by_original_instance.display_as = 'cited-by-relationship-instance-name-only'
        end
        results.push(cited_by_original_instance)
      end
    end
    results
  end

end

