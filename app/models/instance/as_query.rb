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

# Instance as query.
class Instance::AsQuery < Instance
  def self.options
    {
      "id" => "with id",
      "name-instances" => "for name",
      "ref-instances" => "for reference",
      "name-id" => "for name id",
      "ref-usages" => "for reference id",
      "reverse-of-cites-id-query" => "that cite instance id",
      "reverse-of-cited-by-id-query" => "cited by instance id",
      "note-key" => "with note key",
      "instance-type" => "with instance type",
      "with-comments" => "with comments",
      "with-comments-by" => "with comments by",
      "cr-a" => "created since",
      "cr-b" => "created before",
      "upd-a" => "updated since",
      "upd-b" => "updated before",
      "nsl-720" => "nsl-720*"
    }
  end
end
