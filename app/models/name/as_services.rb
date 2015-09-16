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

  def self.apni_family_url(id)
    "#{Rails.configuration.name_services}#{id}/api/family"
  end

  def self.delete_url(id,reason = 'No longer required.')
    api_key = Rails.configuration.api_key
    "#{Rails.configuration.name_services}#{id}/api/delete?apiKey=#{api_key}&reason=#{ERB::Util.url_encode(reason)}"
  end

  # Service will send back 200 even if delete fails, but will also sometimes send back 404,
  # so have to look at both.
  # The interface *should* never let a user try to delete a name
  # that cannot be deleted, so the chances of hitting a 'meaningful' error are small.
  # The service error messages are not suitable for showing to users. e.g. "There are 1 that cite this.", raw database messages like multi-level foreign key technical errors,
  # so just log them. 
  def delete_with_reason(reason)
    logger.info("Name::AsServices.delete")
    json = {}
    url = Name::AsServices.delete_url(id,reason)
    s_response = RestClient.delete(url,{accept: :json})
    json = JSON.load(s_response)
    raise "Delete Service said: #{json["errors"].try("join")} [#{s_response.code}]" unless s_response.code == 200 and json["ok"] == true
    true
  rescue => e
    logger.error("Name::AsServices.delete exception : #{e.to_s}")
    logger.error("Name::AsServices.delete exception for url: #{url}")
    logger.error("Name::AsServices.delete exception with s_response: #{s_response}")
    logger.error("Name::AsServices.delete exception with errors: #{json['errors']}")
    raise
  end

end

