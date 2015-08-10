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
class RefType < ActiveRecord::Base

  self.table_name = 'ref_type'
  self.primary_key = 'id'

  belongs_to :parent, class_name: 'RefType', foreign_key: 'parent_id'
  has_many   :children, class_name: 'RefType', foreign_key: 'parent_id', dependent: :restrict_with_exception  
  
  has_many :references
  
  def name?
    name == 'Name'
  end
  
  def unknown?
    name == 'Unknown'
  end

  def indefinite_article
    case name.first.downcase
    when 'i' then 'an'
    when 'h' then 'an'
    when 'u' then 'an'
    else 'a'
    end
  end

  def self.unknown
    RefType.where(name: 'Unknown').push( RefType.order('name').limit(1).first).first
  end

  def self.options
    self.all.order(:name).collect{|r| [r.name, r.id]}
  end

  def rule
    if parent_id.blank?
      rule = "cannot be within another reference"
    elsif parent_optional == true
      rule = "may be within #{parent.indefinite_article} #{parent.name.downcase}"
    else
      rule = "should be within #{parent.indefinite_article} #{parent.name.downcase}"
    end
    "#{indefinite_article.capitalize} #{name.downcase} #{rule}."
  end

  def parent_allowed?
    parent_id.present?
  end

end


