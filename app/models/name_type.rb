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
class NameType < ActiveRecord::Base
  self.table_name = 'name_type'
  self.primary_key = 'id'
  self.sequence_name = 'nsl_global_seq'

  scope :not_deprecated, -> { where(deprecated: false) }

  has_many :names
  belongs_to :name_group
  belongs_to :name_category
  
  def full_name
    if self.parent
      "#{self.parent.full_name} #{self.name}"
    else
      self.name
    end
  end

  def capitalised_name
    case name
    when /\bacra\b/
      name.gsub(/\bacra\b/,'ACRA')
    when /\bpbr\b/
      name.gsub(/\bpbr\b/,'PBR')
    when /\btrade\b/
      name.gsub(/\btrade\b/,'Trade')
    else
      name
    end
  end

  def self.default
    NameType.where(name: 'scientific').push( NameType.order('name').limit(1).first).first
  end

  def self.query_form_options
    self.not_deprecated.sort{|x,y| x.name <=> y.name}.collect{|n| [n.capitalised_name, "#{n.name}", class: '']}.
      unshift(['Include common, cultivars','name-type:*']).unshift(['Exclude common, cultivars',''])
  end

  def self.options
    self.all.sort{|x,y| x.name <=> y.name}.collect{|n| [n.capitalised_name, n.id, class: '']}
  end

  def self.option_ids_for_category(name_category_string)
    NameType.options_for_category(name_category_string).collect{|o| o.second}
  end

  def self.options_for_category(for_category)
    case for_category 
    when Name::SCIENTIFIC_CATEGORY
      self.scientific_1_parent_options
    when Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
      self.scientific_2_parent_options
    when Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
      self.scientific_hybrid_formula_unknown_2nd_parent_options
    when Name::CULTIVAR_HYBRID_CATEGORY
      self.cultivar_hybrid_options
    when Name::CULTIVAR_CATEGORY
      self.cultivar_options
    when Name::OTHER_CATEGORY
      self.other_options
    when 'all'
      self.options
    else
      []
    end
  end

  def self.scientific_1_parent_options
    self.where(scientific: true).
         where(" (not hybrid or name in ('named hybrid','named hybrid autonym'))").
         sort{|x,y| x.name <=> y.name}.collect{|n| [n.name, n.id]}
  end

  def self.scientific_2_parent_options
    self.where(" name in ('cultivar hybrid formula', 'graft/chimera') or (scientific and hybrid and name not in ('hybrid formula unknown 2nd parent','named hybrid','named hybrid autonym'))").
         sort{|x,y| x.name <=> y.name}.collect{|n| [n.name, n.id]}
  end

  def self.scientific_hybrid_formula_unknown_2nd_parent_options
    self.where(" name in ('hybrid formula unknown 2nd parent')").
         sort{|x,y| x.name <=> y.name}.collect{|n| [n.name, n.id]}
  end
         
  def self.cultivar_hybrid_options
    self.where(scientific: false).
         where(deprecated: false).
         where(cultivar: true).
         where(hybrid: true).
         where(" name not in ('cultivar hybrid formula', 'graft/chimera')").
         sort{|x,y| x.name <=> y.name}.
         collect do |n| 
           [n.name, n.id, class: 'cultivar_hybrid']
         end
  end
         
  def self.cultivar_options
    self.where(scientific: false).
         where(deprecated: false).
         where(cultivar: true).
         where(hybrid: false).
         where(" name not in ('cultivar hybrid formula', 'graft/chimera')").
         sort{|x,y| x.name <=> y.name}.
         collect do |n| 
           [n.name, n.id, class: 'cultivar']
         end
  end

  def self.other_options
    self.where(scientific: false).where(cultivar: false).sort{|x,y| x.name <=> y.name}.collect do |n| 
      [n.name, n.id, class: 'other']
    end
  end

  def hybrid?
    self.hybrid
  end

  def cultivar?
    self.cultivar
  end

  def scientific?
    scientific == true
  end

  def category
    case self.name 
      when '[default]'                         then 'other'
      when '[unknown]'                         then 'other'
      when '[n/a]'                             then 'other'
      when 'scientific'                        then 'scientific_1_parent'
      when 'sanctioned'                        then 'scientific_1_parent'
      when 'hybrid'                            then 'scientific_2_parents'
      when 'hybrid formula parents known'      then 'scientific_2_parents'
      when 'hybrid formula unknown 2nd parent' then 'scientific_1_parent'
      when 'named hybrid'                      then 'scientific_1_parent'
      when 'named hybrid autonym'              then 'scientific_1_parent'
      when 'hybrid autonym'                    then 'scientific_2_parents'
      when 'intergrade'                        then 'scientific_2_parents'
      when 'autonym'                           then 'scientific_1_parent'
      when 'cultivar'                          then 'cultivar'
      when 'cultivar hybrid'                   then 'cultivar'
      when 'cultivar hybrid formula'           then 'scientific_2_parents'
      when 'acra'                              then 'cultivar'
      when 'acra hybrid'                       then 'cultivar'
      when 'pbr'                               then 'cultivar'
      when 'pbr hybrid'                        then 'cultivar'
      when 'trade'                             then 'cultivar'
      when 'trade hybrid'                      then 'cultivar'
      when 'graft/chimera'                     then 'scientific_2_parents'
      when 'informal'                          then 'other'
      when 'common'                            then 'other'
      else 'other'
    end
  end

end
