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
    belongs_to :parent, class_name: "Orchid", foreign_key: "parent_id"
    has_many :children,
             class_name: "Orchid",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception


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
    Name.where(simple_name: taxon)
  end
end
