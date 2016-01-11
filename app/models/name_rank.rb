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
class NameRank < ActiveRecord::Base
  self.table_name = "name_rank"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_many :names
  belongs_to :name_group

  NEEDS_GENERIC_EPITHET = %w(Subgenus Sectio Subsectio Series Subseries Superspecies Species)
  NEEDS_SPECIFIC_EPITHET = %w(Subspecies Nothosubspecies Nothovarietas Varietas Subvarietas Forma Subforma morphological nothomorph.)

  Species = "Species"
  Genus = "Genus"
  Familia = "Familia"
  Family = Familia
  NA = "[n/a]"
  Unranked = "[unranked]"

  def needs_generic_epithet
    NEEDS_GENERIC_EPITHET.include?(name)
  end

  def needs_specific_epithet
    NEEDS_SPECIFIC_EPITHET.include?(name)
  end

  def epithet_type
    if needs_generic_epithet
      return "Generic"
    elsif needs_specific_epithet
      return "Specific"
    else
      return nil
    end
  end

  def self.default
    NameRank.where(abbrev: "sp.").push(NameRank.first).first
  end

  def self.sample(n = 20)
    NameRank.first(n).each do |name_rank|
      ap name_rank
      puts "epithet_type: #{name_rank.epithet_type}"
    end
  end

  def self.options_for_category(name_category = :unknown)
    case name_category
    when Name::SCIENTIFIC_CATEGORY
      options
    when Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
      options
    when Name::CULTIVAR_HYBRID_CATEGORY
      cultivar_hybrid_options
    when Name::CULTIVAR_CATEGORY
      cultivar_options
    else
      options
    end
  end

  def self.options
    where("deprecated is false").order(:sort_order).collect { |n| [n.name, n.id] }
  end

  def self.query_form_options
    where("deprecated is false").order(:sort_order).collect { |n| [n.name, "rank: #{n.name.downcase}"] }
  end

  def self.query_form_ranked_below_options
    where("deprecated is false").order(:sort_order).collect { |n| [n.name, "below-rank: #{n.name.downcase}"] }
  end

  def self.query_form_ranked_above_options
    where("deprecated is false").order(:sort_order).collect { |n| [n.name, "above-rank: #{n.name.downcase}"] }
  end

  def self.cultivar_hybrid_options
    where("deprecated is false")
      .where("(name not like '%[%' or name = '[unranked]') ")
      .where(" sort_order >= (select sort_order from name_rank where lower(name) = 'species')")
      .order(:sort_order).collect { |n| [n.name, n.id] }
  end

  def self.cultivar_options
    where("deprecated is false")
      .where("name not like '%[%' or name = '[unranked]' ")
      .where(" sort_order >= (select sort_order from name_rank where lower(name) = 'species')")
      .order(:sort_order).collect { |n| [n.name, n.id] }
  end

  def self.id_is_unranked?(id)
    candidate = NameRank.find_by(id: id)
    candidate.present? && candidate.name == "[unranked]"
  end

  def deprecated?
    deprecated
  end

  def species?
    !!name.match(/\A#{Species}\z/)
  end

  def genus?
    !!name.match(/\A#{Genus}\z/)
  end

  def self.not_applicable
    find_by(name: NA).id
  end

  def na?
    !!name.match(/\A#{Regexp.escape(NA)}\z/)
  end

  def unranked?
    !!name.match(/\A#{Regexp.escape(Unranked)}\z/)
  end

  def self.genus
    NameRank.find_by(name: Genus)
  end

  # if rank below species, species
  # elsif rank below genus, genus
  # elsif rank genus, nil
  # elsif rank below family, family
  # else (rank above family), nil
  def parent
    if deprecated?
      DeprecatedNoParent.new
    elsif na?
      NoParent.new
    elsif below_species?
      NameRank.species
    elsif below_genus?
      NameRank.genus
    elsif genus?
      NameRank.family
    elsif below_family?
      NameRank.family
    else
      NoParent.new
    end
  end

  # Note: greater than means below!
  def below_species?
    sort_order > NameRank.species.sort_order
  end

  # Note: greater than means below!
  def below_genus?
    sort_order > NameRank.genus.sort_order
  end

  # Note: greater than means below!
  def below_family?
    sort_order > NameRank.family.sort_order
  end

  def self.species
    find_by(name: Species)
  end

  def self.family
    find_by(name: Family)
  end

  def self.print_parent_divisions
    NameRank.all.each { |name_rank| puts "#{name_rank.name}  #{name_rank.below_species? ? 'is below species' : ''}" }
    ""
  end

  def self.print_parents
    NameRank.all.each { |name_rank| printf("%20s:  %s\n", name_rank.name, name_rank.parent.try("name")) }
    ""
  end

  def self.print_takes_parent
    NameRank.all.each { |name_rank| printf("%20s:  %s\n", name_rank.name, name_rank.parent.takes_parent? ? "takes parent" : "does not take parent") }
    ""
  end

  def takes_parent?
    unranked? || parent.real_parent?
  end

  def real_parent?
    true
  end

  def takes_any_parent?
    unranked?
  end

  def above?(other_name_rank)
    sort_order < other_name_rank.sort_order
  end

  def has_parent?
    sort_order > NameRank.minimum(:sort_order)
  end
end

class NoParent
  def name
    "No parent"
  end

  def real_parent?
    false
  end

  def id
    -1
  end
end

class UnknownParent < NoParent
  def name
    "Unknown parent"
  end
end

class DeprecatedNoParent < NoParent
  def name
    "No parent because deprecated"
  end
end
