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

#  We need to place Orchids on a draft tree.
class Orchid::AsTreePlacer
  attr_reader :status, :error, :placed_count
  ERROR = 'error'
  def initialize(draft_tree, orchid)
    @draft_tree = draft_tree
    @draft_name = draft_tree.draft_name
    @status = 'started'
    @orchid = orchid
    @placed_count = 0
    @error = ''
    preflight_checks
    unless @status == ERROR
      peek
      @placed_count = place_or_replace
    end
  end

  def preflight_checks
    case 
    when @draft_tree.blank?
      @status = ERROR
      @error = "No such draft #{@draft_tree.draft_name}"
    when @orchid.preferred_match.blank?
      @status = ERROR
      @error = "No preferred matching name for #{@orchid.taxon}"
    when @orchid.orchids_name.blank? || @orchid.orchids_name.first.standalone_instance_id.blank?
      @status = ERROR
      @error = "No instance identified for #{@orchid.taxon}"
    when @orchid.orchids_name.first.drafted?
      @status = ERROR
      @error = "Stopping because #{@orchid.taxon} is already on the draft tree"
    when @orchid.exclude_from_further_processing?
      @status = ERROR
      @error = "#{@orchid.taxon} is excluded from further processing"
    when @orchid.parent.try('exclude_from_further_processing?')
      @status = ERROR
      @error = "Parent of #{@orchid.taxon} is excluded from further processing"
    when @orchid.hybrid_cross?
      @status = ERROR
      @error = "#{@orchid.taxon} is a hybrid cross - not ready to process these"
    end
  end

  def peek
    debug("#{'peek '*20}")
    debug("@orchid.class: #{@orchid.class}")
    debug("@draft_tree.class: #{@draft_tree.class}")
    debug("@draft_tree.tree.config: #{@draft_tree.tree.config}")
    debug("@draft_tree.tree.config['comment_key']: #{@draft_tree.tree.config['comment_key']}")
    debug("@draft_tree.tree.config['distribution_key']: #{@draft_tree.tree.config['distribution_key']}")
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
    @orchid.orchids_name.each do |one_orchid_name|
      debug("one_orchid_name: id #{one_orchid_name.id}")
      debug("one_orchid_name.standalone_instance: #{one_orchid_name.standalone_instance}")
      debug("one_orchid_name.standalone_instance.name: #{one_orchid_name.standalone_instance.name}")
      debug("one_orchid_name.standalone_instance.name.simple_name: #{one_orchid_name.standalone_instance.name.simple_name}")
      debug("@draft_tree.id: #{@draft_tree.inspect}")
      debug("one_orchid_name.standalone_instance.name.draft_instance_id(@draft_tree): #{one_orchid_name.standalone_instance.name.draft_instance_id(@draft_tree)}")
      debug "name: #{one_orchid_name.name_id}; instance: #{one_orchid_name.standalone_instance_id}"
      if one_orchid_name.standalone_instance_id.blank?
        debug "No instance identified, therefore cannot place this on the APC Tree."
      elsif one_orchid_name.drafted?
        debug "Stopping because already drafted."
      else
        @tree_version_element = @draft_tree.name_in_version(one_orchid_name.name)
        if @tree_version_element.present?
          debug 'name is on the draft: replace it'
          return replace_name(one_orchid_name)
        #elsif one_orchid_name.name.draft_instance_id(@draft_tree).present?
        #elsif one_orchid_name.standalone_instance.name.draft_instance_id(@draft_tree) != one_orchid_name.standalone_instance.id
          #debug 'name is in the draft already'
          #replace_name(one_orchid_name)
        else
          debug 'name is not on the draft: just place it'
          return place_name(one_orchid_name)
        end
      end
    end
  end

  def place_name(orchids_name)
    tree_version = @draft_tree
    debug("parent_element_link: #{parent_tve(orchids_name).element_link}")
    placement = Tree::Workspace::Placement.new(username: 'gclarke',
                                               parent_element_link: parent_tve(orchids_name).element_link,
                                               instance_id: orchids_name.standalone_instance_id,
                                               excluded: false,
                                               profile: profile,
                                               version_id: @draft_tree.id)
    response = placement.place
    debug(json_result(response))
    orchids_name.drafted = true
    orchids_name.save!
    1
  end

  def replace_name(orchids_name)
    debug("replace_name #{orchids_name.name.full_name}")
    debug("parent_element_link: #{parent_tve(orchids_name).element_link}")
    parent_tve = parent_tve(orchids_name)
    debug("parent_tve.element_link: #{parent_tve.element_link}")
    debug("parent_tve.name_path: #{parent_tve.name_path}")
    debug("parent_tve.tree_version.draft_name: #{parent_tve.tree_version.draft_name}")
    debug("@tree_version_element: #{@tree_version_element}")
    debug("@draft_tree.name_in_version(orchids_name.name): #{@draft_tree.name_in_version(orchids_name.name)}")

    replacement = Tree::Workspace::Replacement.new(username: 'gclarke',
                                                 target: @tree_version_element,
                                                 parent: parent_tve(orchids_name),
                                                 instance_id: orchids_name.standalone_instance_id,
                                                 excluded: false,
                                                 profile: profile)
    debug('after call to Tree::Workspace::Replacement')
    response = replacement.replace
    debug('after call to replacement.replace')
    debug(json_result(response))
    orchids_name.drafted = true
    orchids_name.save!
    1
  end 

  def parent_tve(orchids_name)
    @draft_tree.name_in_version(orchids_name.name.parent)
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
                             value: @orchid.distribution.split(' | ').join(', '),
                             updated_by: 'gclarke',
                             updated_at: Time.now.utc.iso8601
                             }
    end
    debug(hash.inspect)
    hash
  end

  private

  def debug(msg)
    Rails.logger.debug("Orchid::AsTreePlacer #{msg}")
  end
end
