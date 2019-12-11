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
  def initialize(orchid, reference)
    announce "Instance Creator for orchid: #{orchid.taxon} (#{orchid.record_type})"
    @orchid = orchid
    @ref = reference
  end

  def create_instance_for_preferred_matches
    records = 0
    debug('  Create instance for preferred matches')
    return 0 if stop_everything?
    @orchid.preferred_match.each do |preferred_match|
      if preferred_match.standalone_instance_created
        return 1
      elsif preferred_match.standalone_instance_found
        return 0
      else
        debug('      Create instance')
        preferred_match.create_instance(@ref)
        records += 1
      end
    end
    records
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
    Rails.logger.debug(msg)
  end
end
