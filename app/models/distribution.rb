# frozen_string_literal: true
#   Copyright 2018 Australian National Botanic Gardens
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
class Distribution < ActiveRecord::Base
  self.table_name = "distribution"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  validates :description, presence: true
  validates :region, presence: true
  validates :sort_order, presence: true

  def self.display_order
    Distribution.order(sort_order: :asc)
  end

  def doubtfully_naturalised?
    is_doubtfully_naturalised
  end

  def extinct?
    is_extinct
  end

  def native?
    is_native
  end

  def naturalised?
    is_naturalised
  end

end
