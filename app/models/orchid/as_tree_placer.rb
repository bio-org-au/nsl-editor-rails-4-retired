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

#  Name services
class Orchid::AsTreePlacer
  
  def initialize(tree_version_draft_name, orchid)
    debug("tree_version_draft_name: #{tree_version_draft_name}")
    @orchid = orchid
    @tree_version = Tree::DraftVersion.where(draft_name:
                                                   tree_version_draft_name)
                                            .first
    throw "No such draft #{tree_version_draft_name}" if @tree_version.blank?
    peek
    place_or_replace
  end

  def peek
    debug("@orchid.class: #{@orchid.class}")
    debug("@tree_version.class: #{@tree_version.class}")
    debug("@tree_version.tree.config: #{@tree_version.tree.config}")
    debug("@tree_version.tree.config['comment_key']: #{@tree_version.tree.config['comment_key']}")
    debug("@tree_version.tree.config['distribution_key']: #{@tree_version.tree.config['distribution_key']}")
  end

  # From @orchid work out the name and instance you're interested in.
  # 
  # for all the preferred names/instances of the orchid
  # loop
  #   if the name is on the draft
  #     replace it
  #   else
  #     place it
  #   end
  # end
  def place_or_replace
    debug('place_or_replace')
    return if stop_everything?
    @orchid.orchids_name.each do |orchids_name|
      debug "name: #{orchids_name.name_id}; instance: #{orchids_name.standalone_instance_id}"
      if orchids_name.standalone_instance_id.blank?
        debug "No instance identified, therefore cannot place this on the APC Tree."
      elsif orchids_name.drafted?
        debug "Stopping because already drafted."
      else
          tree_version_element = @tree_version.name_in_version(orchids_name.name)
        if @tree_version_element.present?
          debug 'name is on the draft: replace it'
          replace_name(orchids_name)
        else
          debug 'name is not on the draft: just place it'
          place_name(orchids_name)
        end
      end
    end
  end

  def stop_everything?
    if @orchid.exclude_from_further_processing?
      debug('  Orchid is excluded from further processing.')
      return true
    elsif @orchid.parent.try('exclude_from_further_processing?')
      debug("  Orchid's parent is excluded from further processing.")
      return true
    elsif @orchid.hybrid_cross?
      debug("  Orchid is a hybrid cross - not ready to process these.")
      return true
    end
    false
  end

  def name_is_on_the_draft?(the_name)
    @tree_version_element = @tree_version.name_in_version(the_name)
    return @tree_version_element.present?
  end

  def place_name(orchids_name)
    tree_version = @tree_version
    debug("parent_element_link: #{parent_tve(orchids_name).element_link}")
    placement = Tree::Workspace::Placement.new(username: 'gclarke',
                                               parent_element_link: parent_tve(orchids_name).element_link,
                                               instance_id: orchids_name.standalone_instance_id,
                                               excluded: false,
                                               profile: profile,
                                               version_id: @tree_version.id)
    response = placement.place
    debug(json_result(response))
    orchids_name.drafted = true
    orchids_name.save!
    'placed'
  end

  def replace_name(orchids_name)
    debug("replace_name #{orchids_name.name.full_name}")
    debug("parent_element_link: #{parent_tve(orchids_name).element_link}")
    parent_tve = parent_tve(orchids_name)
    debug("parent_tve.element_link: #{parent_tve.element_link}")
    debug("parent_tve.name_path: #{parent_tve.name_path}")
    debug("parent_tve.tree_version.draft_name: #{parent_tve.tree_version.draft_name}")

    replacement = Tree::Workspace::Replacement.new(username: 'gclarke',
                                                 target: @tree_version_element,
                                                 parent: parent_tve(orchids_name),
                                                 instance_id: orchids_name.standalone_instance_id,
                                                 excluded: false,
                                                 profile: profile)
    response = replacement.replace
    debug(json_result(response))
    orchids_name.drafted = true
    orchids_name.save!
    'replaced'
  end 

  def parent_tve(orchids_name)
    @tree_version.name_in_version(orchids_name.name.parent)
  end

  def json_result(result)
    json_payload(result)&.message || result.to_s
  rescue
    result.to_s
  end

  # I did try to use the Tree::ProfileData class, 
  # but it couldn't find the comment_key or distribution_key
  # without new methods and (more importantly) it requires 
  # a @current_user, which the batch job doesn't have.
  def profile
    hash = {}
    unless @orchid.comment.blank?
      hash['APC Comment'] = { value: @orchid.comment,
                              updated_by: 'gclarke',
                              updated_at: Time.now.utc.iso8601}
    end
    unless @orchid.distribution.blank?
      hash['APC Dist.'] = {
                             value: @orchid.distribution.split(' | ').join(','),
                             updated_by: 'gclarke',
                             updated_at: Time.now.utc.iso8601
                             }
    end
    debug(hash.inspect)
    hash
  end

  def debug(msg)
    puts msg
  end
end

