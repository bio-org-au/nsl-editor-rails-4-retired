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
class Name::AsServices < Name

  def self.name_strings_url(id)
    "#{Rails.configuration.name_services}#{id}/api/name-strings"
  end

  def self.in_apc_url(id)
    "#{Rails.configuration.name_services}#{id}/api/apc"
  end

  def self.in_apni_url(id)
    "#{Rails.configuration.name_services}#{id}/api/apni"
  end

  def self.apni_info_url(id)
    "#{Rails.configuration.name_services}#{id}/api/family"
  end

  def self.apni_info_json(id)    
    Rails.cache.fetch("apni_family_name:#{id}", expires: 1.minute) do ||
      logger.debug("Uncached service call for apni_family_name:#{id}")
      JSON.load(open(Name::AsServices.apni_info_url(id)))
    end
  end

end


