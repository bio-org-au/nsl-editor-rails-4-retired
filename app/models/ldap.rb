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
    Ldap.new.admin_search(Rails.configuration.ldap_groups, "uniqueMember", "uid=#{username}", "cn")
  rescue => e
    Rails.logger.error("Error in Ldap#users_groups for username: #{username}")
    Rails.logger.error(e.to_s)
    return ["error"]
  end

  # Users full name.
  def user_full_name
    Rails.logger.info('Ldap#user_full_name')
    Ldap.new.admin_search(Rails.configuration.ldap_users, "uid", username, "cn").first || username
  rescue => e
    Rails.logger.error("Error in Ldap#user_full_name for username: #{username}")
    Rails.logger.error(e.to_s)
    return username
  end

  # Known groups
  def self.groups
    Ldap.new.admin_search(Rails.configuration.ldap_groups, "objectClass", "groupOfUniqueNames", "cn")
  end

  # Return an array of search results
  def admin_search(base, attribute, value, print_attribute)
    Rails.logger.info("Ldap#admin_search: base: #{base}; attribute: #{attribute}, value: #{value}, print_attribute: #{print_attribute}")
    filter = Net::LDAP::Filter.eq(attribute, value)
    result = admin_connection.search(base: base, filter: filter).try("collect") do |entry|
      Rails.logger.info("Found something: #{entry}")
      entry.send(print_attribute)
    end.try("flatten") || []
    fail admin_connection.get_operation_result.error_message if admin_connection.get_operation_result.error_message.present?
    result
  end

  private

  def admin_connection
    Rails.logger.info("Connecting to LDAP")
    ldap = Net::LDAP.new
    ldap.host = Rails.configuration.ldap_host
    ldap.port = Rails.configuration.ldap_port
    ldap.auth Rails.configuration.ldap_admin_username, Rails.configuration.ldap_admin_password
    Rails.logger.error("LDAP error - #{ldap.get_operation_result.error_message}") unless ldap.bind
    ldap
  end

  def validate_user_credentials
    Rails.logger.info("Validate user credentials")
    result = admin_connection.bind_as(
      base: Rails.configuration.ldap_users,
      filter: Net::LDAP::Filter.eq("uid", username),
      password: password)
    unless result
      errors.add(:connection, "failed")
      Rails.logger.error("Validating user credentials (user authentication) failed.")
    end
  rescue => e
    Rails.logger.error("Exception in validate_user_credentials")
    Rails.logger.error(e.to_s)
    errors.add(:connection, "connection failed with exception")
  end
end
