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
# Orchids table
class Orchid < ActiveRecord::Base
  attr_accessor :name_id, :instance_id
    belongs_to :parent, class_name: "Orchid", foreign_key: "parent_id"
    has_many :children,
             class_name: "Orchid",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception
    has_many :orchids_name
    scope :avoids_id, ->(avoid_id) { where("orchids.id != ?", avoid_id) }

  def self.create(params, username)
    orchid = Orchid.new(params)
    orchid.id = next_sequence_id
    orchid.family = 'Orchidaceae'
    if orchid.save_with_username(username)
      orchid
    else
      raise orchid.errors.full_messages.first.to_s
    end
  end


  def display_as
    'Orchid'
  end

  def synonym?
    record_type == 'synonym'
  end

  def fresh?
    false
  end

  def child?
    !parent_id.blank?
  end

  def names_simple_name_matching_taxon
    Name.where(["simple_name = ? or simple_name = ?",taxon, alt_taxon_for_matching]).joins(:name_type).where(name_type: {scientific: true}).order("simple_name, name.id")
  end

  def matches
    names_simple_name_matching_taxon
  end

  def name_match_no_primary
    !Name.where(["name.simple_name = ? and exists (select null from name_type nt where name.name_type_id = nt.id and scientific) and not exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)",taxon.gsub(/[‘’]/,"'")]).empty?
  end

  def synonym_type_with_interpretation
    "#{synonym_type} (#{interpreted_synonym_type})"
  end

  def interpreted_synonym_type
    case synonym_type
    when 'homotypic'
      'nomenclatural'
    when 'heterotypic'
      'taxonomic'
    else
      'unknown'
    end
  end

  def has_parent?
    !parent_id.blank?
  end

  def misapplied?
    record_type == 'misapplied'
  end

  def homotypic?
    synonym_type == 'homotypic'
  end

  def heterotypic?
    synonym_type == 'heterotypic'
  end

  def pp?
    partly == 'p.p.'
  end

  def riti
    return InstanceType.find_by_name('misapplied').id if misapplied?
    if heterotypic?
      if pp?
        return InstanceType.find_by_name('pro parte taxonomic synonym').id
      else
        return InstanceType.find_by_name('taxonomic synonym').id
      end
    end
    if homotypic?
      Rails.logger.debug('homotypic')
      if pp?
        Rails.logger.debug('pp')
        return InstanceType.find_by_name('pro parte nomenclatural synonym').id
      else
        return InstanceType.find_by_name('nomenclatural synonym').id
      end
    end
    Rails.logger.debug('Will be unknown')
    return InstanceType.unknown.id
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  # We use a custom sequence because the data is initially loaded from a CSV file with allocated IDs.
  # This is only for subsequent records we add.
  def self.next_sequence_id
    ActiveRecord::Base.connection.execute("select nextval('orchids_seq')").first['nextval']
  end

  def update_if_changed(params, username)
    params = empty_strings_should_be_nils(params)
    assign_attributes(params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  # Empty strings as parameters for string fields are interpreted as a change.
  def empty_strings_should_be_nils(params)
    %w(hybrid, family, hr_comment, subfamily, tribe, subtribe, rank, nsl_rank, taxon,
 ex_base_author, base_author, ex_author, author, author_rank, name_status, name_comment,
 partly, auct_non, synonym_type, doubtful, hybrid_level, isonym, article_author, article_title,
 article_title_full, in_flag, author_2, title, title_full, edition, volume, page,
 year, date_, publ_partly, publ_note, note, footnote, distribution, comment,
 remark, original_text).each do |field|
    params[field] = nil if params[field] == ""
    end
    params
  end

  def ok_to_delete?
    children.empty? && orchids_name.empty?
  end

  def accepted?
    record_type == 'accepted'
  end
end
