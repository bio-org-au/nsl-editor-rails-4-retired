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
  strip_attributes
  REF_ID = 51316736
  attr_accessor :name_id, :instance_id
    belongs_to :parent, class_name: "Orchid", foreign_key: "parent_id"
    has_many :children,
             class_name: "Orchid",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception
    has_many :orchids_name
    has_many :preferred_match, class_name: :OrchidsName, foreign_key: :orchid_id
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

  validates :synonym_type,
            presence: { if: "record_type == 'synonym'",
                        message: "is required." }
 

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

  # Note: not case-insensitive. Perhaps should be.
  def names_simple_name_matching_taxon
    Name.where(["simple_name = ? or simple_name = ?",taxon, alt_taxon_for_matching])
        .joins(:name_type).where(name_type: {scientific: true})
        .order("simple_name, name.id")
  end

  def matches
    names_simple_name_matching_taxon
  end

  def name_match_no_primary?
    !Name.where(["(name.simple_name = ? or name.simple_name = ?) and exists (select null from name_type nt where name.name_type_id = nt.id and scientific) and not exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)",taxon, alt_taxon_for_matching]).empty?
  end

  def matches_with_primary
    Name.where(["(name.simple_name = ? or name.simple_name = ?) and exists (select null from name_type nt where name.name_type_id = nt.id and scientific) and exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)", taxon, alt_taxon_for_matching])
  end

  def no_matches_with_primary?
    matches_with_primary.empty?
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

  def misapp?
    misapplied?
  end

  def misapplied?
    record_type == 'misapplied'
  end

  def homotypic?
    synonym_type == 'homotypic' || 
      synonym_type == 'nomenclatural synonym'
  end

  def nomenclatural?
    homotypic?
  end

  def heterotypic?
    synonym_type == 'heterotypic' || 
      synonym_type == 'taxonomic synonym'
  end

  def taxonomic?
    heterotypic?
  end

  def pp?
    partly == 'p.p.'
  end

  # r relationship
  # i instance
  # t type
  # i id
  def riti
    return nil if accepted?
    return InstanceType.find_by_name('misapplied').id if misapplied?
    if taxonomic?
      if pp?
        return InstanceType.find_by_name('pro parte taxonomic synonym').id
      else
        return InstanceType.find_by_name('taxonomic synonym').id
      end
    elsif nomenclatural?
      if pp?
        return InstanceType.find_by_name('pro parte nomenclatural synonym').id
      else
        return InstanceType.find_by_name('nomenclatural synonym').id
      end
    elsif InstanceType.where(name: synonym_type).size == 1
      return InstanceType.find_by_name(synonym_type).id
    elsif synonym_type.blank?
      throw "The orchid is a synonym with no synonym type - please set a synonym type in 'Edit Raw' then try again."
    else
      throw "Orchid#riti cannot work out an instance type for orchid: #{id}: #{taxon} #{record_type} #{synonym_type}"
    end
    throw "Orchid#riti is stuck with no relationship instance type id for orchid: #{id}: #{taxon}"
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

  def hybrid_cross?
    record_type == 'hybrid_cross'
  end

  def misapplied?
    record_type == 'misapplied'
  end

  def doubtful?
    doubtful == true
  end

  def create_preferred_match
    AsNameMatcher.new(self).find_or_create_preferred_match
  end

  def self.create_preferred_matches_for(taxon_s)
    throw 'deprecated'
    debug("create_preferred_matches_for #{taxon_s}")
    records = 0
    self.where(["taxon like ?", taxon_s.gsub(/\*/,'%')])
        .order(:seq).each do |match|
      records += match.create_preferred_match
      match.children.each do |child|
        records += child.create_preferred_match
      end
    end
    records
  end

  def self.create_preferred_matches_for_accepted_taxa(taxon_s)
    debug("create_preferred_matches_for_accepted_taxa matching #{taxon_s}")
    records = 0
    self.where(record_type: 'accepted')
        .where(["taxon like ?", taxon_s.gsub(/\*/,'%')])
        .order(:seq).each do |match|
      records += match.create_preferred_match
      match.children.each do |child|
        records += child.create_preferred_match
      end
    end
    records
  end

  def self.create_instance_for_preferred_matches_for(taxon_s)
    debug('create_instance_for_preferred_matches_for')
    records = 0
    @ref = Reference.find(REF_ID)
    self.where(["taxon like ?", taxon_s.gsub(/\*/,'%')])
        .where(record_type: 'accepted').order(:id).each do |match|
      records += match.create_instance_for_preferred_matches
      match.children.each do |child|
        records += child.create_instance_for_preferred_matches
      end
    end
    records
  end

  def create_instance_for_preferred_matches
    debug("create_instance_for_preferred_matches")
    @ref = Reference.find(REF_ID) if @ref.blank?
    throw 'No ref!' if @ref.blank?
    AsInstanceCreator.new(self,@ref).create_instance_for_preferred_matches
  end

  # check for preferred name
  def self.add_to_tree_for(draft_tree, taxon_s)
    count = 0
    errors = ''
    self.where(["taxon like ?", taxon_s]).where(record_type: 'accepted').order(:id).each do |match|
      placer = AsTreePlacer.new(draft_tree, match)
      count += placer.placed_count
      errors += placer.error + ';' unless placer.error.blank?
    end
    return count, errors
  end

  def isonym?
    return false if isonym.blank?
    true
  end

  def orth_var?
    return false if name_status.blank?
    name_status.downcase.match(/\Aorth/)
  end

  def self.name_statuses
    sql = "select name_status, count(*) total from orchids where name_status is not null group by name_status order by name_status"
    records_array = ActiveRecord::Base.connection.execute(sql)
  end

  def synonym_without_synonym_type?
    synonym? & synonym_type.blank?
  end

  private

  def debug(msg)
    Rails.logger.debug("Orchid##{msg}")
  end

  def self.debug(msg)
    Rails.logger.debug("Orchid##{msg}")
  end

end

