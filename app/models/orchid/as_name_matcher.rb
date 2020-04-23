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
class Orchid::AsNameMatcher
  def initialize(orchid)
    puts '='*70
    announce "Name matcher for orchid: #{orchid.taxon} (#{orchid.record_type})"
    @orchid = orchid
  end

  def find_or_create_preferred_match
    if @orchid.exclude_from_further_processing?
      return 0
    elsif preferred_match?
      return 0
    elsif make_preferred_match?
      return 1
    else
      return 0
    end
  end

  def stop(msg)
    puts "Stopping because: #{msg}"
  end

  def preferred_match?
    debug '      Look for an existing preferred match'
    return !@orchid.preferred_match.empty?
  end

  def make_preferred_match?
    debug "      Make preferred match for #{@orchid.id} #{@orchid.taxon} #{@orchid.record_type}"
    if exactly_one_matching_name? &&
         matching_name_has_primary? &&
         matching_name_has_exactly_one_primary?
      pref = @orchid.orchids_name.new
      pref.name_id = @orchid.matches.first.id
      pref.instance_id = @orchid.matches.first.primary_instances.first.id
      pref.relationship_instance_type_id = @orchid.riti
      pref.created_by = pref.updated_by = 'batch'
      pref.save!
      true
    else
      false
    end
  end

  def exactly_one_matching_name?
    case @orchid.matches.size
    when 0
      puts '        No matches!'
      return false
    when 1
      return true
    else
      puts '        too many matches'
      return false
    end
  end

  def matching_name_has_primary?
    !@orchid.name_match_no_primary?
  end

  def matching_name_has_exactly_one_primary?
    @orchid.matches.first.primary_instances.size == 1
  end

  def relationship_instance_type_id
    return nil if @orchid.accepted?
    return @orchid.riti
  end

  def taxon
    @orchid.taxon
  end

  def record_failure(msg)
    msg.sub!(/uncaught throw /,'')
    msg.gsub!(/"/,'')
    msg.sub!(/^Failing/,'')
    debug "Failure: #{msg}"
  end

  def announce(msg)
    debug "="*(msg.length)
    debug msg
    debug "="*(msg.length)
  end

  def debug(msg)
    Rails.logger.debug("#{msg}")
  end
end
