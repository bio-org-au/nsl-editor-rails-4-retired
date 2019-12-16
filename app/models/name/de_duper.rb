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

# I can Deduplicate a name
# I have a name I can deduplicate
# 
class Name::DeDuper
  def initialize(duplicate_name)
    @duplicate = duplicate_name
    identify_master
    identify_dependencies
    debug("De-duplicating name: #{@duplicate.id} #{@duplicate.full_name}")
  end

  def de_dupe
    debug('De-duplicating.... not actually...')
  end

  def preview
    overview
  end

  def overview
    result = Hash.new
    # family members
    result[:children] = @children.size
    result[:second_children] = @second_children.size
    result[:instances] = @instances.size
    result[:duplicates_of] = @duplicates_of.size
    result[:tree_elements] = @tree_elements.size
    result[:comments] = @comments.size
    result[:name_tag_names] = @name_tag_names.size
    result[:in_family] = @in_family.size
    result
  end

  def tree_elements?
    @tree_elements.size > 0
  end

  def tree_elements
    @duplicate.tree_elements
  end

  def tree_version_elements
    @duplicate.tree_elements.first.tree_version_elements
  end

  def tree_versions
    @duplicate.tree_elements.collect do | te |
      te.tree_version_elements.collect do |tve|
        tve.tree_version
      end
    end
  end

  def trees
    @duplicate.tree_elements.collect do | te |
      te.tree_version_elements.collect do |tve|
        tve.tree_version.tree
      end
    end.flatten
  end

  def trees_2
    t = @duplicate.tree_elements.collect do |te|
          te.tree_version_elements.collect {|tve| tve.tree_version.tree.name + '::' +
                                                  tve.tree_version.draft_name + '::' +
                                                  tve.tree_version.published.to_s}
        end
    t
  end
 
  private

  def identify_master
    @master = @duplicate.duplicate_of
    validate_master
  end

  # Note: exclude the case of duplicate of a duplicate, because that
  # trail of duplicates could lead back to the current duplicate
  # In this early version we want to keep things simple
  def validate_master
    throw "No master" if @master.blank?
    debug("Master name: #{@master.id} #{@master.full_name}")
    unless @master.duplicate_of_id.blank?
      debug("Master is also a duplicate")
      throw "We do not de-duplicate where the master is also a duplicate"
    end
  end

  def identify_dependencies
    @children = @duplicate.children
    debug("children: #{@children.size}")
    @second_children = @duplicate.second_children
    debug("second children: #{@second_children.size}")
    @instances = @duplicate.instances
    debug("instances: #{@instances.size}")
    @duplicates_of = Name.where(duplicate_of_id: @duplicate.id)
    debug("duplicates of: #{@duplicates_of.size}")
    @tree_elements = TreeElement.where(name_id: @duplicate.id)
    debug("tree elements: #{@tree_elements.size}")
    @comments = @duplicate.comments
    debug("comments: #{@comments.size}")
    @name_tag_names = @duplicate.name_tag_names
    debug("name tag names: #{@name_tag_names.size}")
    @in_family = Name.where(family_id: @duplicate.id)
    debug("names in family: #{@in_family.size}")
  end

  def debug(msg)
    #Rails.logger.debug('De-duplicating....')
    puts(msg)
  end
end
