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
class InstanceNote < ActiveRecord::Base
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  before_create :set_defaults
  self.table_name = "instance_note"
  self.primary_key = "id"
  belongs_to :instance
  belongs_to :instance_note_key
  validates :value, presence: true
  validates :instance_note_key_id, presence: true
  scope :apc, -> { joins(:instance_note_key).where('instance_note_key.name' => ["APC Comment", "APC Dist."]) }
  scope :non_apc, -> { joins(:instance_note_key).where.not('instance_note_key.name' => ["APC Comment", "APC Dist."]) }

  def set_defaults
    self.namespace_id = Namespace.apni.id if namespace_id.blank?
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update_attributes!(attributes)
  end
end
