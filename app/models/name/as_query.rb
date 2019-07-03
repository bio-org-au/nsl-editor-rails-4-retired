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

# Name querying.
class Name::AsQuery < Name
  def self.options
    {
      "a" => "with author",
      "with-tag" => "with tag",
      "ba" => "with base author",
      "with-comments" => "with comments",
      "with-comments-by" => "with comments by",
      "with-comments-but-no-instances" => "comment no instan",
      "ea" => "with ex author",
      "eba" => "with ex base author",
      "fn" => "with full name",
      "sn" => "with simple name",
      "ne" => "with name element",
      "nt" => "with name type",
      "not-nt" => "with not name type",
      "nr" => "with name rank",
      "ns" => "with name status",
      "sa" => "with sanctioning auth",
      "id" => "with id",
      "duplicate-of" => "duplicate of",
      "is-a-duplicate" => "is a duplicate",
      "orth-var-but-no-orth-var-instances" => "orth var no ov inst",
      "ids" => "with ids",
      "for-reference" => "for reference",
      "hours-since-created" => "hours since created",
      "hours-since-updated" => "hours since updated",
      "cr-a" => "created since",
      "cr-b" => "created before",
      "upd-a" => "updated since",
      "upd-b" => "updated before",
      "a-id" => "author id",
      "ba-id" => "base author id",
      "ea-id" => "ex author id",
      "eba-id" => "ex base author id",
      "sa-id" => "sanctioning author id",
      "parent-id" => "parent id",
      "second-parent-id" => "second parent id",
      "children" => "children"
    }
  end
end
