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
# Author entity: name strings and abbreviation strings for individuals or
# groups of individuals who have authored a reference or authorised a name.
class Author < ActiveRecord::Base
  strip_attributes

  self.table_name = "author"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  attr_accessor :display_as, :give_me_focus, :message

  scope :lower_name_equals,
        ->(string) { where("lower(name) = ? ", string.downcase) }
  scope :lower_name_like,
        ->(string) { where("lower(name) like ? ", string.gsub(/\*/, "%").downcase) }
  scope :lower_abbrev_like,
        ->(string) { where("lower(abbrev) like ? ", string.gsub(/\*/, "%").downcase) }
  scope :not_this_id,
        ->(this_id) { where.not(id: this_id) }
  scope :not_duplicate,
        -> { where("author.duplicate_of_id is null") }

  has_many :references
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"

  has_many :names
  has_many :ex_names, foreign_key: "ex_author_id", class_name: "Name"
  has_many :base_names, foreign_key: "base_author_id", class_name: "Name"
  has_many :ex_base_names,
           foreign_key: "ex_base_author_id",
           class_name: "Name"
  has_many :sanctioned_names,
           foreign_key: "sanctioning_author_id",
           class_name: "Name"

  belongs_to :duplicate_of, class_name: "Author", foreign_key: "duplicate_of_id"
  has_many :duplicates,
           -> { order("name") },
           class_name: "Author",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_error
  has_many :comments

  validates :name,
            presence: { if: "abbrev.blank?",
                        message: "can't be blank if abbrev is blank." }
  validates :abbrev,
            presence: { if: "name.blank?",
                        message: "can't be blank if name is blank." }

  validates :abbrev,
            uniqueness: { unless: "abbrev.blank?",
                          case_sensitive: false,
                          message: "has already been used"}

  validates_exclusion_of :duplicate_of_id,
                         in: ->(author) { [author.id] },
                         allow_blank: true,
                         message: "and master cannot be the same record"

  scope :lower_abbrev_equals,
        ->(string) { where("lower(abbrev) = lower(?) ", string) }

  scope :created_n_days_ago,
        ->(n) { where("current_date - created_at::date = ?", n) }
  scope :updated_n_days_ago,
        ->(n) { where("current_date - updated_at::date = ?", n) }
  scope :changed_n_days_ago,
        ->(n) { where("current_date - created_at::date = ? or current_date - updated_at::date = ?", n, n) }

  scope :created_in_the_last_n_days,
        ->(n) { where("created_at::date > current_date - ?", n) }
  scope :updated_in_the_last_n_days,
        ->(n) { where("updated_at::date > current_date - ?", n) }
  scope :changed_in_the_last_n_days,
        ->(n) { where("created_at::date > current_date - ? or updated_at::date > current_date - ?", n, n) }

  DEFAULT_DESCRIPTOR = "n" # for name
  DEFAULT_ORDER_BY = "name asc "

  before_create :set_defaults

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def name_and_or_abbrev
    if name.present? && abbrev.present?
      "#{name} | #{abbrev}"
    elsif name.present?
      "#{name}"
    elsif abbrev.present?
      "#{abbrev}"
    else
      id.to_string
    end
  end

  def master_of
    Author.where(duplicate_of_id: id)
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def update_attributes_with_username(attributes, username)
    self.updated_by = username
    update_attributes(attributes)
  end

  def abbrev_if_possible
    abbrev || "[No abbreviation - id: #{id}]"
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def anchor_id
    "Author-#{id}"
  end

  def unknown
    name == "-"
  end

  def known
    !unknown
  end

  def set_defaults
    self.namespace_id = Namespace.apni.id if namespace_id.blank?
  end

  def citation
    abbrev || "[no author citation]"
  end

  def name_for_citation
    case name
    when /\A-\z/
      ""
    else
      "#{name.strip}"
    end
  end

  def can_be_deleted?
    names.size == 0 &&
      references.size == 0 &&
      duplicates.size == 0 &&
      base_names.size == 0 &&
      ex_names.size == 0 &&
      ex_base_names.size == 0 &&
      sanctioned_names.size == 0
  end
end
