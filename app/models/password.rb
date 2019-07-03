# frozen_string_literal: true

#   Copyright 2019 Australian National Botanic Gardens
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
class Password < ActiveType::Object
  attribute :current_password, :string
  validates :current_password, presence: true
  attribute :new_password, :string
  validates :new_password, presence: true
  attribute :new_password_confirmation, :string
  validates :new_password_confirmation, presence: true
  attribute :username, :string

  def save!
    validate_arguments
    Rails.logger.debug('save!')
    Rails.logger.debug("username: #{username}")
    Rails.logger.debug("new_password: #{new_password}")
    change_password
    true
  rescue => e
    Rails.logger.error("Error changing password: #{e.to_s}")
    @error = e.to_s
    false
  end

  def error
    @error ||= ''
  end

  private

  def validate_arguments
    raise "no current password entered" if current_password.blank? 
    raise "no new password entered" if new_password.blank? 
    raise "new password was not confirmed" if new_password_confirmation.blank? 
    unless new_password == new_password_confirmation
      raise "new password was not confirmed correctly"
    end
    raise "new password not long enough" if new_password.size < 8
    raise "new password too long" if new_password.size > 25
  end

  def change_password
    ldap = Ldap.new
    ldap.username = username
    ldap.password = current_password
    raise 'current password is wrong' unless ldap.verify_current_password
    ldap.change_password(username, new_password,random_seed)
  end

  def random_seed
    (0...8).map { (97 + rand(26)).chr }.join
  end
end
