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
class Ldap < ActiveType::Object
  attribute :username, :string
  attribute :password, :string

  validates :username, presence: true
  validates :password, presence: true

  validate :validate_user_credentials

  # Groups user is assigned to.
  def users_groups
    Rails.logger.info("Ldap#users_groups")
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
    Rails.logger.info("Ldap#user_full_name")
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
      raise admin_connection.get_operation_result.error_message
    end
    result
  end

  # See https://github.com/ruby-ldap/ruby-net-ldap/issues/290
  def change_password(uid,new_password,salt)
    conn = admin_connection
    digest = Digest::SHA1.digest("#{new_password}#{salt}")
    person = conn.search(base: Rails.configuration.ldap_users, filter: Net::LDAP::Filter.eq("uid",uid))
    new_hashed_password = "{SSHA}"+Base64.encode64(digest+salt).chomp!
    conn.replace_attribute(person.first.dn, 'userPassword', new_hashed_password)
  end

  def verify_current_password
    validate_user_credentials
  end

  def admin_connection
    Rails.logger.info("Connecting to LDAP")
    ldap = Net::LDAP.new
    Rails.logger.info("Rails.configuration.ldap_host: #{Rails.configuration.ldap_host}")
    Rails.logger.info("Rails.configuration.ldap_port: #{Rails.configuration.ldap_port}")
    Rails.logger.info("Rails.configuration.ldap_admin_username: #{Rails.configuration.ldap_admin_username}")
    ldap.port = Rails.configuration.ldap_port
    ldap.host = Rails.configuration.ldap_host
    ldap.auth Rails.configuration.ldap_admin_username,
              Rails.configuration.ldap_admin_password
    unless ldap.bind
      Rails.logger.error("LDAP error: #{ldap.get_operation_result.error_message}")
      raise "Failed admin connection!"
    end
    Rails.logger.info("Admin connection to LDAP succeeded")
    ldap
  end

  private

  def validate_user_credentials
    result = admin_connection.bind_as(
      base: Rails.configuration.ldap_users,
      filter: Net::LDAP::Filter.eq("uid", username),
      password: password
    )
    unless result
      errors.add(:connection, "failed")
      Rails.logger.error("Validating user credentials failed.")
      return false
    end
    return true
  rescue => e
    Rails.logger.error("Exception in validate_user_credentials")
    Rails.logger.error(e.to_s)
    errors.add(:connection, "connection failed with exception")
  end
end
