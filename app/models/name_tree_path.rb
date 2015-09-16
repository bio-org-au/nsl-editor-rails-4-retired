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
class NameTreePath < ActiveRecord::Base
 
  self.table_name = 'name_tree_path'
  self.primary_key = 'id'

  belongs_to :name
  
  before_create :prevent_operation
  before_update :prevent_operation
  before_destroy :prevent_operation

  def prevent_operation 
    raise 'No create, update or destroy allowed for name_tree_path'
  end

  def collected
    path.split('.').collect {|id| Name.find(id.to_i)}
  end


end

