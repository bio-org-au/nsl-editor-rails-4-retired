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
class Language < ActiveRecord::Base
  self.table_name = "language"
  self.primary_key = "id"
  has_many :references
  ORDER_BY = "case name when 'Undetermined' then 'AAA' \
  when 'English' then 'AAB' when 'French' then 'AAC' when 'German' then 'AAD'\
  when 'Latin' then 'AAE' else name end"

  def self.unknown
    find_by(name: "Undetermined")
  end

  def self.default
    find_by(name: "Undetermined")
  end

  # For any language select list.
  def self.options
    all.order(ORDER_BY).collect do |lang|
      [lang.name, lang.id]
    end.insert(5, ["──────────", "disabled"])
  end

  def self.english
    find_by(name: "English")
  end

  def determined?
    name != "Undetermined"
  end
end
