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
#  Reference entity - books, papers, journals, etc
class Reference < ActiveRecord::Base
  include PgSearch
  include AuditScopable
  include ReferenceAssociations
  include ReferenceScopes
  include ReferenceValidations
  include ReferenceRefTypeValidations
  include ReferenceCitations
  require "open-uri"
  self.table_name = "reference"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  strip_attributes

  attr_accessor :display_as, :message

  before_validation :set_defaults
  before_create :set_defaults
  before_save :validate

  def day
    return nil if iso_publication_date.nil?
    return nil if iso_publication_date.length < 9
    iso_publication_date.match(/..\z/)
  end

  def day=(dd)
    return if month.blank?
    return if dd == 0
    if dd.nil?
      Rails.logger.debug("we have at most year and month")
      if month.nil?
        self.iso_publication_date = year
      else
        self.iso_publication_date = "#{year}-#{month}"
      end
    else
      unless iso_publication_date.nil? || iso_publication_date.length < 7
        self.iso_publication_date = "#{iso_publication_date.match(/^....-../)}-#{dd.to_s.rjust(2, "0")}"
      end
    end
  end

  def month
    return nil if iso_publication_date.nil?
    return nil if iso_publication_date.length < 7
    return iso_publication_date.scan(/..\z/).first if iso_publication_date.length == 7 
    return iso_publication_date.scan(/(?<=....\-)..(?=-..)/).first
  end

  def month=(mm)
    Rails.logger.debug("month= for mm: #{mm}")
    return if iso_publication_date.nil?
    return if year.blank?
    if mm.nil?
      Rails.logger.debug("we have just year")
      self.iso_publication_date = year
    elsif iso_publication_date.length == 4 || iso_publication_date.length == 7    # yyyy or yyyy-mm
      self.iso_publication_date = "#{iso_publication_date.match(/^..../)}-#{mm.to_s.rjust(2, '0')}"
    elsif iso_publication_date.length == 10 # yyyy-mm-dd
      self.iso_publication_date = "#{iso_publication_date.match(/^..../)}-#{mm.to_s.rjust(2, '0')}-#{day}"
    end
  end

  def year
    return nil if iso_publication_date.nil?
    return nil if iso_publication_date.length < 4
    return iso_publication_date.scan(/\A..../).first
  end

  def year=(yyyy)
    if iso_publication_date.nil? || iso_publication_date.length <= 4
      self.iso_publication_date = yyyy
    elsif iso_publication_date.length == 7
      self.iso_publication_date = "#{yyyy}-#{month}"
    elsif iso_publication_date.length == 10
      self.iso_publication_date = "#{yyyy}-#{month}-#{day}"
    end
  end

  def children?
    children.size.positive?
  end

  def instances?
    instances.size.positive?
  end

  def validate
    errors[:base].size.zero?
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update_attributes!(attributes)
  end

  def anchor_id
    "Reference-#{id}"
  end

  def pages_useless?
    pages.blank? || pages.match(/null - null/)
  end

  def self.find_authors
    ->(name) { Author.where(" lower(name) = lower(?)", name.downcase) }
  end

  def self.find_references
    ->(title) { Reference.where(" lower(title) = lower(?)", title.downcase) }
  end

  def self.dummy_record
    find_by_title("Unknown")
  end

  def display_as_part_of_concept
    self.display_as = :reference_as_part_of_concept
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def published?
    published
  end

  def set_defaults
    self.language_id = Language.default.id if language_id.blank?
    self.display_title = title if display_title.blank?
    self.namespace_id = Namespace.default.id
  end

  def parent_has_same_author?
    parent && author.name
                    .match(/\A#{Regexp.escape(parent.author.name)}\z/)
                    .positive?
  end

  def typeahead_display_value
    type = ref_type.name.downcase
    #"#{citation} |#{' [' + pages + ']' unless pages_useless?} [#{type}] #{ iso_publication_date.strftime("%d-%b-%Y") unless iso_publication_date.blank?}"
    #"<nobr>#{citation} |#{' [' + pages + ']' unless pages_useless?} [#{type}] #{ iso_publication_date unless iso_publication_date.blank? }</nobr>"
    "#{citation} |#{' [' + pages + ']' unless pages_useless?} [#{type}]"
  end

  def self.count_search_results(raw)
    logger.debug("Counting references")
    just_count_them = true
    count = search(raw, just_count_them)
    logger.debug(count)
    count
  end

  def ref_type_options
    if children.size.zero?
      RefType.options
    else
      RefType.options_for_parent_of(children.collect(&:ref_type))
    end
  end

  def part_parent_year
    return nil unless ref_type.part?
    parent.year
  end
end
