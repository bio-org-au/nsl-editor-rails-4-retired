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
class InstanceNoteKey < ActiveRecord::Base
  self.table_name = 'instance_note_key'
  self.primary_key = 'id'
  has_many :instance_notes
  
  def self.options
    self.all.where(deprecated: false).order(:sort_order).collect{|n| [n.name, n.id]}
  end

  def self.query_form_options
    self.all.where(deprecated: false).sort{|x,y| x.name <=> y.name}.collect{|n| [n.name, n.name.downcase, class: '']}
  end

end
