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
#   

class Instance::AsSearchEngine < Instance


  def self.for_name_id(name_id)
    Instance::AsSearchEngine.name_usages(name_id)
  end

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
      name.display_as_part_of_concept
      already_shown = []
      name.instances.sort do |i1,i2| 
        [i1.reference.year||9999,i1.instance_type.primaries_first,i1.reference.author.try('name')||'x'] <=> [i2.reference.year||9999,i2.instance_type.primaries_first,i2.reference.author.try('name')||'x'] 
      end.each do |instance|
        logger.debug('after ruby sort')
        if instance.simple? # simple instance
          Instance::AsSearchEngine.show_simple_instance_under_searched_for_name(instance).each do |one_instance|
            one_instance.show_primary_instance_type = true
            one_instance.consider_apc = true
            results.push(one_instance)
          end
        else # relationship instance
          citing_instance = instance.this_is_cited_by
          unless already_shown.include?(citing_instance.id)
            Instance::AsSearchEngine.show_relationship_instance_under_searched_for_name(name,citing_instance).each do |element|
              element.consider_apc = false
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

  # Instances of a name algorithm: work on a single simple instance starts here.
  # - display the instance as part of a concept
  # - find all child instances using the cited_by_id column (all instances that say they are cited by the simple instance)
  #   - display these relationship instances as cited_by the simple instance
  def self.show_simple_instance_under_searched_for_name(instance)
    results = [instance.display_as_part_of_concept]
    Instance.joins(:instance_type, :name, :reference).
      where(cited_by_id: instance.id).
      in_nested_instance_type_order.
      order("reference.year,lower(name.full_name)").
      each do |cited_by_original_instance|
        cited_by_original_instance.expanded_instance_type = cited_by_original_instance.instance_type.name
        cited_by_original_instance.display_as = 'instance-is-cited-by'
        results.push(cited_by_original_instance)
      end
    results
  end
  
  # NSL-536: If instance name is not the subject name then do not show the instance type.
  def self.show_relationship_instance_under_searched_for_name(name,instance)
    results = [instance.display_as_citing_instance_within_name_search]
    Instance.joins(:instance_type).
             where(cited_by_id: instance.id).
             in_nested_instance_type_order.
             each do |cited_by_original_instance|
      if cited_by_original_instance.name.id == name.id
        cited_by_original_instance.expanded_instance_type = cited_by_original_instance.instance_type.name
        cited_by_original_instance.display_as = cited_by_original_instance.misapplied? ? 'cited-by-relationship-instance' : 'cited-by-relationship-instance-name-only'
        results.push(cited_by_original_instance)
      end
    end
    results
  end
  
end

