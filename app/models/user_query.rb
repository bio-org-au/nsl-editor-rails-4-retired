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
require 'advanced_search'
require 'search_tools'
require 'audit'

class UserQuery < ActiveRecord::Base
  self.table_name = 'user_query'
  self.primary_key = 'id'
  self.sequence_name = 'user_query_id_seq'


  attr_accessor :display_as, :give_me_focus
  # attr_accessible  :search_model, :search_result, :search_terms, :created_at
  serialize :search_result
  
  def run_search
    case search_model.downcase
    when 'instance'
      search_results,rejected_pairings,limited,save_search = Instance.search(search_terms)
    when 'name'
      search_results,rejected_pairings,limited,focus_anchor_id,search_info  = Name.search(search_terms)
      # update_attribute(:search_result, search_results.collect {|name| hash = name.attributes.to_options; hash[:display_as] = 'Name'; hash['anchor_id'] = ''; hash })
    else
      logger.error("UserQuery#run_search cannot search on this model: #{search_model.downcase}")
    end
    update_attribute(:query_completed, 'Y')
    if search_results
      # Convert array of Name records to an array of hashes before saving in serialized column.
      # This is to avoid each record being queried during the unserialization that occurs during retrieval of the user_query record.
      sr = search_results.collect do |rec|
        if rec.is_a? Name
          # Convert to a hash to avoid the re-querying that goes with unserializing an activerecord object.
          hash = rec.attributes.to_options; hash[:display_as] = rec.class.name
          hash['anchor_id'] = ''
          hash
        else
          rec  # Return the active record object because we rely on associations to display instances.  
               # Also, I haven't prepared the display chain to handle hashes for Authors or Refernces.
        end
      end
      update_attribute(:search_result,sr)
      update_attribute(:record_count,search_results.size)
    end
    
  end

  def anchor_id
    "Query-#{self.id}"
  end
  
  
end
