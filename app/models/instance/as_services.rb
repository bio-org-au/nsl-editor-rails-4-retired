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
class Instance::AsServices < Instance
  def self.name_strings_url(id)
    "#{Rails.configuration.name_services}#{id}/api/name-strings"
  end

  def self.tag
    "Instance::AsServices"
  end

  # Service will send back 200 even if delete fails, but will also sometimes
  # send back 404, so have to look at both. Sigh.
  #
  # (PMc Note) Actually...A 404 is sent if the target is not found, but
  # when the target of the delete *is* found but you can't delete it because
  # it is referenced, you get a 403 Forbidden. Looking at it again we should 
  # possibly return 409 conflict... don't you love interpreting standards (RFC 7231)
  #
  # The interface *should* never let a user try to delete an instance
  # that cannot be deleted, so the chances of hitting a 'meaningful' error
  # should be small but experience has shown this happens.
  # The service error messages are not always good for showing to users, but
  # users need to see them, so we attribute them.
  #
  # RestClient throws exceptions for 403, 404 type errors and we handle those
  # based on the structured response to extract a meaningful message.
  def self.delete(id)
    logger.info("#{tag}.delete")
    url = delete_uri(id)
    response = RestClient.delete(url, accept: :json)
    json = JSON.parse(response)
    unless response.code == 200 && json["ok"] == true
      raise "Service error: #{json['errors'].try('join')} [#{response.code}]"
    end
  rescue RestClient::ExceptionWithResponse => rest_client_exception
    logger.error("Instance::AsServices.delete exception for url: #{url}")
    logger.error(rest_client_exception.response)
    json = JSON.parse(rest_client_exception.response)
    logger.error("#{tag}.delete exception response.errors: #{json['errors'].join(';')}")
    raise json["errors"].join(";")
  rescue
    logger.error("#{tag}.delete exception for url: #{url}")
    raise
  end

  def self.delete_uri(id)
    api_key = Rails.configuration.api_key
    host_path = "#{Rails.configuration.services}rest/instance/apni/#{id}/api/delete"
    "#{host_path}?apiKey=#{api_key}&reason=Edit"
  end
end
