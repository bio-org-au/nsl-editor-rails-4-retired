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
# Workspaces are trees that can have value nodes for instances.
# This view shows the values for an instance in a workspace.
class WorkspaceInstanceValue < ActiveRecord::Base
  self.table_name = "workspace_instance_value_vw"
  belongs_to :instance
  belongs_to :workspace, class_name: "Tree::Workspace", foreign_key: "workspace_id"
end
