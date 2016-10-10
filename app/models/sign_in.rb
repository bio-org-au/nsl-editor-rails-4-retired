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
class SignIn < ActiveType::Object
  attribute :username, :string
  attribute :password, :string

  validates :username, presence: true
  validates :password, presence: true

  validate :validate_credentials

  def groups
    build_ldap.users_groups
  end

  def user_full_name
    build_ldap.user_full_name
  end

  def web_token
    # do service call to ask the service layer for the JWT

    api_key = Rails.configuration.api_key
    address = Rails.configuration.nsl_services
    path = "auth/getInfoJsonForUsername"
    url = "#{address}#{path}?apiKey=#{api_key}&username=#{username}"

    logger.info url

    s_response = RestClient.get(url, accept: :json)
    json = JSON.load(s_response)
    if json && json['success'] == true
      json[:jwt]
    else
      logger.error("SignIn::webToken url: #{url}")
      logger.error("SignIn::webToken s_response: #{s_response}")
      logger.error("SignIn::webToken json: #{json}")
      # I do not raise an error, because I do not want the editor to
      # crash if the services are down. Comonents in service-oriented
      # architectures must be built to limp along as best they can
      # when other bits are down, or else nothing ever works
      nil
    end
  end

  private

  def validate_credentials
    errors.add(:credentials, "not verified.") unless build_ldap.save
  end

  def build_ldap
    credentials = {}
    credentials[:username] = username
    credentials[:password] = password
    Ldap.new(credentials)
  end

end
