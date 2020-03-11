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
  strip_attributes
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
  validates :relationship_instance_type_id, :presence => true, :unless => "orchid.accepted?"

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
    debug("create_instance")
    @ref = ref
    if orchid.accepted?
      debug("OrchidsName#create_instance orchid is accepted")
      return create_or_find_standalone_instance
    elsif orchid.synonym?
      debug("OrchidsName#create_instance orchid is synonym")
      return create_or_find_relationship_instance
    elsif orchid.hybrid?
      debug("OrchidsName#create_instance orchid is hybrid")
      throw 'dont know how to handle hybrid'
    elsif orchid.misapplied?
      return create_or_find_misapplied_instance
    end
  end

  def create_or_find_standalone_instance
    debug 'create_or_find_standalone_instance'
    return 0 if standalone_instance?
    debug 'no standalone instance, so we will create one'
    create_standalone_instance
  end

  def create_standalone_instance
    debug('create_standalone_instance')
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
    return 1
  rescue => e
    logger.error("OrchidsName#create_standalone_instance: #{e.to_s}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub(/uncaught throw/,'').gsub(/"/,'')
    render 'error'
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
      debug '        Relationship instance already there returning 0'
      return 0
    end
    if relationship_instance?
      debug '        Relationship instance found returning 0'
      return 0
    end
    debug('need to create a relationship instance')
    return create_relationship_instance
  end

  def relationship_instance?
    return false if orchid.parent.orchids_name.blank?
    return false if orchid.parent.orchids_name.first.try('standalone_instance_id').blank?
    instances = Instance.where(name_id: name_id)
                        .where(cites_id: instance_id)
                        .where(cited_by_id: orchid.parent.orchids_name.first.try('standalone_instance_id'))
    if instances.blank?
      return false
    else
      debug '        relationship instance!'
      debug "        relationship instances: #{instances.size}"
      return true
    end
  end

  # 
  def create_relationship_instance
    debug('create_relationship_instance start')
    if orchid.parent.orchids_name.first.try('standalone_instance_id').blank?
      debug('parent has no standalone instance so cannot create relationship instance')
      return 0
    end
    debug('Going on to create relationship instance')
    new_instance = Instance.new
    new_instance.draft = false
    new_instance.cited_by_id = orchid.parent.orchids_name.first.standalone_instance_id
    new_instance.reference_id = orchid.parent.orchids_name.first.standalone_instance.reference_id
    new_instance.cites_id = instance_id
    new_instance.name_id = instance.name_id
    throw "No relationship instance type id for #{orchid_id} #{orchid.taxon}" if relationship_instance_type_id.blank?
    new_instance.instance_type_id = relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = 'nsl-3422'
    new_instance.save!
    self.relationship_instance_created = true
    self.relationship_instance_id = new_instance.id
    self.save!
    return 1
  end

  # create_or_find_relationship_instance
  def create_or_find_misapplied_instance
    if relationship_instance_id.present?
      debug '        misapplied instance already there'
      return 0
    end
    if relationship_instance?
      debug '        misapplied instance found'
      return 0
    end
    create_misapplied_instance
  end

  def create_misapplied_instance
    debug('        Create misapplied instance')
    new_instance = Instance.new
    new_instance.draft = false
    new_instance.cited_by_id = orchid.parent.orchids_name.first.standalone_instance_id
    new_instance.reference_id = orchid.parent.orchids_name.first.standalone_instance.reference_id
    new_instance.cites_id = instance_id
    new_instance.name_id = instance.name_id
    new_instance.instance_type_id = relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = 'nsl-3422'
    new_instance.save!
    self.relationship_instance_created = true
    self.relationship_instance_id = new_instance.id
    self.save!
    return 1
  rescue => e
    logger.error("OrchidsName#create_misapplied_instance: #{e.to_s}")
    logger.error e.backtrace.join("\n")
    return 0
  end

  def debug(msg)
    Rails.logger.debug("OrchidsName: #{msg}")
  end
end

