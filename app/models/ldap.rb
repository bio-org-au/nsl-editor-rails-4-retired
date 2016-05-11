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
class Ldap < ActiveType::Object
  attribute :username, :string
  attribute :password, :string

  validates :username, presence: true
  validates :password, presence: true

  validate :validate_user_credentials

  # Groups user is assigned to.
  def users_groups
    Rails.logger.info('Ldap#users_groups')
    Ldap.new.admin_search(Rails.configuration.ldap_groups,
                          "uniqueMember",
                          "uid=#{username}", "cn")
  rescue => e
    Rails.logger.error("Error in Ldap#users_groups for username: #{username}")
    Rails.logger.error(e.to_s)
    return ["error"]
  end

  # Users full name.
  def user_full_name
    Rails.logger.info('Ldap#user_full_name')
    Ldap.new.admin_search(Rails.configuration.ldap_users,
                          "uid",
                          username,
                          "cn").first || username
  rescue => e
    Rails.logger.error("Error in Ldap#user_full_name for username: #{username}")
    Rails.logger.error(e.to_s)
    return username
  end

  # Known groups
  def self.groups
    Ldap.new.admin_search(Rails.configuration.ldap_groups,
                          "objectClass",
                          "groupOfUniqueNames",
                          "cn")
  end

  # Return an array of search results
  def admin_search(base, attribute, value, print_attribute)
    filter = Net::LDAP::Filter.eq(attribute, value)
    result = admin_connection.search(base: base,
                                     filter: filter).try("collect") do |entry|
      entry.send(print_attribute)
    end.try("flatten") || []
    if admin_connection.get_operation_result.error_message.present?
      fail admin_connection.get_operation_result.error_message
    end
    result
  end

  private

  def admin_connection
    Rails.logger.info("Connecting to LDAP (admin_connection)")
    ldap = Net::LDAP.new
    Rails.logger.info("got object")
    ldap.host = Rails.configuration.ldap_host
    Rails.logger.info("set host: #{ldap.host}")
    ldap.port = Rails.configuration.ldap_port
    Rails.logger.info("set port: #{ldap.port}")
    ldap.auth Rails.configuration.ldap_admin_username,
              Rails.configuration.ldap_admin_password
    Rails.logger.info("set ldap.auth")
    Rails.logger.info("about to ldap.bind")
    ldap.bind
    ldap
  end


    #unless ldap.bind
      #Rails.logger.error("Could not ldap.bind as admin user to LDAP server")
      #Rails.logger.error("ldap.host: #{ldap.host}")
      #Rails.logger.error("ldap.port: #{ldap.port}")
      #Rails.logger.error("user: #{Rails.configuration.ldap_admin_username}")
      #Rails.logger.error(admin_connection.try("get_operation_result").try("error_message"))
      #throw "LDAP admin connection failed"
    #end
    #Rails.logger.info("admin_connection succeeded")
    #ldap
  #end

  def validate_user_credentials
    Rails.logger.info("Validate user credentials")
    result = admin_connection.bind_as(
      base: Rails.configuration.ldap_users,
      filter: Net::LDAP::Filter.eq("uid", username),
      password: password)
    unless result
      errors.add(:connection, "failed")
      Rails.logger.error("Validating user credentials failed.")
    end
  #rescue => e
    #Rails.logger.error("Exception in validate_user_credentials")
    #Rails.logger.error("Error: #{e.to_s}")
    #Rails.logger.error("Could not connect to LDAP server")
    #Rails.logger.error("ldap.host: #{Rails.configuration.ldap_host}")
    #Rails.logger.error("ldap.port: #{Rails.configuration.ldap_port}")
    #Rails.logger.error("username: #{username}")
    #Rails.logger.error("Op result:- ")
    #Rails.logger.error(admin_connection.try("get_operation_result").try("error_message"))
    #errors.add(:connection, "connection failed with exception")
  end
end
