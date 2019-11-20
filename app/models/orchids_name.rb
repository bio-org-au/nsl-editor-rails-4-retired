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
# Orchids table
class OrchidsName < ActiveRecord::Base
  belongs_to :name
  belongs_to :instance
  belongs_to :standalone_instance, class_name: 'Instance', foreign_key: 'standalone_instance_id'
  belongs_to :instance_type, foreign_key: :relationship_instance_type_id
  belongs_to :orchid
  belongs_to :tree_element, foreign_key: 'standalone_instance_id'
  validates :name_id, uniqueness: { scope: :orchid_id, message: 'Cannot reuse same name for the same orchid taxon'},
            unless: Proc.new {|a| a.orchid.record_type == 'misapplied'}

  validates :orchid_id, uniqueness: true,
            unless: Proc.new {|a| a.orchid.record_type == 'misapplied'}

  ###########################################################
  #
  #  if for accepted?
  #    create or look for a standalone instance
  #  elsif for synonym
  #    make sure the orchids parent has an instance
  #    create or look for a relationship instance between the chah instance for
  #      the accepted name and the primary instance of the synonym
  #  elsif for hybrid?
  #    not sure yet
  #  elsif for misapp?
  #    not sure yet
  #  end
  #
  ###########################################################
  def create_instance(ref)
    @ref = ref
    if orchid.accepted?
      create_or_find_standalone_instance
    elsif orchid.synonym?
      create_or_find_relationship_instance
    elsif orchid.hybrid?
      throw 'dont know how to handle hybrid'
    elsif orchid.misapplied?
      create_or_find_misapplied_instance
    end
  end

  def create_or_find_standalone_instance
    puts 'create_or_find_standalone_instance'
    return if standalone_instance?
    puts 'no standalone instance'
    create_standalone_instance
  end

  def create_standalone_instance
    instance = Instance.new
    instance.draft = true
    instance.name_id = name_id
    instance.reference_id = @ref.id 
    instance.instance_type_id = InstanceType.secondary_reference.id
    instance.created_by = instance.updated_by = 'nsl-3422'
    instance.save!
    self.standalone_instance_created = true
    self.standalone_instance_id = instance.id
    self.save!
  end

  # Is there already instance linking the name to the chah 2018 ref?
  #
  # What about a protologue instance for the name with another reference?
  def standalone_instance?
    return true unless standalone_instance_id.blank?
    instances =  Instance.where(name_id: name_id).where(reference_id: @ref_id)
    case instances.size
    when 0
      return false 
    when 1
      self.standalone_instance_id = instances.first.id
      self.standalone_instance_found = true
      self.save
      return true
    else
      throw 'Too many standalone instances'
    end
  end

  def create_or_find_relationship_instance
    if relationship_instance_id.present?
      puts '        Relationship instance already there'
      return
    end
    if relationship_instance?
      puts '        Relationship instance found'
      return
    end
    create_relationship_instance
  end

  def relationship_instance?
    instances = Instance.where(name_id: name_id)
                        .where(cites_id: instance_id)
                        .where(cited_by_id: orchid.parent.orchids_name.first.standalone_instance_id)
    if instances.blank?
      return false
    else
      puts '        relationship instance!'
      puts "        relationship instances: #{instances.size}"
      return true
    end
  end

  # 
  def create_relationship_instance
    debug('Create relationship instance')
    new_instance = Instance.new
    new_instance.draft = true
    new_instance.cited_by_id = orchid.parent.orchids_name.first.standalone_instance_id
    new_instance.reference_id = orchid.parent.orchids_name.first.standalone_instance.reference_id
    new_instance.cites_id = instance_id
    new_instance.name_id = instance.name_id
    new_instance.instance_type_id = relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = 'nsl-3422'
    new_instance.save!
    debug("new relationship instance: #{new_instance.inspect}")
    self.relationship_instance_created = true
    self.relationship_instance_id = new_instance.id
    self.save!
  end

  # create_or_find_relationship_instance
  def create_or_find_misapplied_instance
    if relationship_instance_id.present?
      puts '        misapplied instance already there'
      return
    end
    if relationship_instance?
      puts '        misapplied instance found'
      return
    end
    create_misapplied_instance
  end

  def create_misapplied_instance
    puts('        Create misapplied instance')
    new_instance = Instance.new
    new_instance.draft = true
    new_instance.cited_by_id = orchid.parent.orchids_name.first.standalone_instance_id
    new_instance.reference_id = orchid.parent.orchids_name.first.standalone_instance.reference_id
    new_instance.cites_id = instance_id
    new_instance.name_id = instance.name_id
    new_instance.instance_type_id = relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = 'nsl-3422'
    new_instance.save!
    debug("new misapplied instance: #{new_instance.inspect}")
    self.relationship_instance_created = true
    self.relationship_instance_id = new_instance.id
    self.save!
  end

  def debug(msg)
    puts "OrchidsName: #{msg}"
  end
end

