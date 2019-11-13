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
class Orchid::AsInstanceCreator
  REF_ID = 51316736

  def initialize(orchid)
    @orchid = orchid
  end

  def taxon
    @orchid.taxon
  end

  def do
    return if @orchid.exclude_from_further_processing?
    ensure_preferred_match
    #create_instance_for_preferred_match
  end

  def ensure_preferred_match
    announce "Ensure preferred match for orchid: #{@orchid.taxon}"
    throw 'Failing: find_or_make_a_preferred_match?' unless find_or_make_a_preferred_match?
    debug('There is a preferred match.')
    announce "Finished ensuring preferred match for Orchid: #{@orchid.taxon}"
  rescue => e
    record_failure(e.to_s)
  end

  def find_or_make_a_preferred_match?
    debug 'Find or make a preferred match'
    return true if preferred_match?
    return make_preferred_match? 
  end

  def preferred_match?
    debug 'Look for an existing preferred match'
    return !@orchid.preferred_match.empty?
  end

  def make_preferred_match?
    debug 'We will try to make a preferred match'
    if exactly_one_matching_name? &&
           matching_name_has_primary? &&
           matching_name_has_exactly_one_primary?
      pref = @orchid.orchids_name.new
      pref.name_id = @orchid.matches.first.id
      pref.instance_id = @orchid.matches.first.primary_instances.first.id
      pref.created_by = pref.updated_by = 'batch'
      pref.relationship_instance_type_id = relationship_instance_type_id
      debug pref.inspect
      pref.save!
      true
    else
      false
    end
  end

  def relationship_instance_type_id
    return nil if @orchid.accepted?
    return @orchid.riti
  end

  def exactly_one_matching_name?
    case @orchid.matches.size
    when 0
      throw 'no matches'
    when 1
      return true
    else
      throw 'too many matches'
    end
  end

  def matching_name_has_primary?
    !@orchid.name_match_no_primary
  end

  def matching_name_has_exactly_one_primary?
    @orchid.matches.first.primary_instances.size == 1
  end

  def find_ref?
    debug 'Find Ref?'
    @ref = Reference.find(REF_ID)
    debug @ref.citation
    true
  end

  def create_instance_for_preferred_match
    throw 'Failing: create_instance?' unless create_instance?
  end

  def create_instance?
    debug 'Create Instance'
    find_ref?
    return true
  end

  def save_everything
    debug 'Save Everything'
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
    puts "#{msg}"
  end
end

