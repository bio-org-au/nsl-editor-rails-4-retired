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
  attr_accessor :name_id
  attr_accessor :instance_id
    belongs_to :parent, class_name: "Orchid", foreign_key: "parent_id"
    has_many :children,
             class_name: "Orchid",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception
    has_many :orchids_name


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
    Name.where(simple_name: taxon).joins(:name_type).where(name_type: {scientific: true}).order("simple_name, name.id")
  end

  def matches
    names_simple_name_matching_taxon
  end

  def name_match_no_primary
    !Name.where(["exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific and exists (select null from name where name.simple_name = ? and not exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)))",taxon]).empty?
  end

  def name_match_no_primary
    !Name.where(["name.simple_name = ? and exists (select null from name_type nt where name.name_type_id = nt.id and scientific) and not exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)",taxon]).empty?
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
end
