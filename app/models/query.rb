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
require 'search_tools'

class Query
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  extend SearchTools

  #self.table_name = 'query'
  Fields = {
            'na' => 'name-author-name',
            'name-author' => 'name-author-name',
            'name-name-author' => 'name-author-name',
            'a-id' => 'name-author-id',
            'name-author-id' => 'name-author-id',
            'ba' => 'name-base-author-name',
            'base-author-name' => 'name-base-author-name',
            'name-base-author-name' => 'name-base-author-name',
            'ea' => 'name-ex-author-name',
            'ex-author-name' => 'name-ex-author-name',
            'name-ex-author-name' => 'name-ex-author-name',
            'eba' => 'name-ex-base-author-name',
            'ex-base-author-name' => 'name-ex-base-author-name',
            'name-ex-base-author-name' => 'name-ex-base-author-name',
            'n' => 'name-full-name',
            'fn' => 'name-full-name',
            'full-name' => 'name-full-name',
            'name-full-name' => 'name-full-name',
            'sn' => 'name-simple-name',
            'simple-name' => 'name-simple-name',
            'name-simple-name' => 'name-simple-name',
            'ne' => 'name-name-element',
            'name-element' => 'name-name-element',
            'name-name-element' => 'name-name-element',
            'nt' => 'name-name-type',
            'name-type' => 'name-name-type',
            'name-name-type' => 'name-name-type',
            'not-nt' => 'not-name-name-type',
            'not-name-name-type' => 'not-name-name-type',
            'not-name-type' => 'not-name-name-type',
            'nr' => 'name-name-rank',
            'name-rank' => 'name-name-rank',
            'name-name-rank' => 'name-name-rank',
            'sa' => 'name-sanctioning-author-name',
            'sanctioning-author-name' => 'name-sanctioning-author-name',
            'name-sanctioning-author-name' => 'name-sanctioning-author-name',
            # reference fields
            'y' => 'ref-year',
            'ry' => 'ref-year',
            'ref-year' => 'ref-year'

           }

  # Turn search string into a hash keyed on field identifiers
  def self.to_hash(search_string)
    logger.debug("to_hash: #{search_string}")
    # Remove the search delimiters - we are relying on unique field ids 
    search_string_clean = search_string.gsub(/;/,'')
    # But here we assume it is a name: search 
    # i.e. if no field indicated we assume full-name (fn)
    formatted_array = format_search_terms('fn',search_string_clean||'')
    standardized_array = self.standardize(formatted_array)
    parts = Hash.new
    standardized_array.each do | pair |
      logger.debug("#{pair.first}: #{pair.last}")
      parts[pair.first] = pair.last
    end
    parts
  end

  def self.standardize(paired_arguments)
    Rails.logger.debug('standardize')
    standard_pairs = paired_arguments.collect do |pair|
      field_name = Fields[pair.first] || 'unknown'
      Rails.logger.debug("pair: #{pair.inspect}; field name: #{field_name}")
      [field_name,pair.last]
    end
    standard_pairs 
  end

end

