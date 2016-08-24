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

require "sinatra"
require "json"

get "/" do
  "<h1>Services</h1>\n" + "<ul>\n" + menu_list + "</ul>\n"
end

def menu_list
  apc_tree_for_name +
    find_out_if_name_in_apni +
    find_out_which_family_a_name_belongs_to +
    new_name_strings +
    construct_reference_citation +
    reference_citation
end

def apc_tree_for_name
  %(<li>Get the <a href="/api/tree/name/APC/91759" >) +
    %(APC tree for a name.</a>\n)
end

def find_out_if_name_in_apni
  %(<li>Find out if a name is ) +
    %(<a href="/nsl/services/name/apni/91755/api/apc.json" >in APC.</a>\n)
end

def find_out_which_family_a_name_belongs_to
  %(<li>Find out which ) +
    %(<a href="/nsl/services/name/apni/91755/api/family.json" >family a ) +
    %(name belongs to.</a>\n)
end

def new_name_strings
  %(<li>Get new <a href="/nsl/services/name/apni/91755/api/name-strings" >) +
    %(name strings.</a>\n)
end

def construct_reference_citation
  %(<li>Get a ) +
    %(<a href="/nsl/services/reference/apni/17575/api/citation-strings.json") +
    %(>newly constructed reference citation.</a>\n)
end

def reference_citation
  %(<li>Get a <a href="/api/ref/citation" >reference citation.</a>\n)
end

get "/api/makeCitation/reference/:id" do |id|
  content_type "application/json"
  result = Reference.new("silly class",
                         { permalink: [] },
                         "citation for id #{id}",
                         "html citation for id #{id}",
                         "unnecessary action",
                         citationHtml:
                         "unnecessarily repeated HTML citation for id #{id}",
                         citation:
                         "unnecessarily repeated citation for id #{id}")
  result.to_json
end

get "/nsl/services/name/apni/:id/api/name-strings" do |id|
  content_type "application/json"
  result = Name.new("silly name class",
                    { permalink: [] },
                    "redundant name element for id #{id}",
                    "unnecessary action",
                    fullMarkedUpName: "full marked up name for id #{id}",
                    simpleMarkedUpName: "simple marked up name for id #{id}",
                    fullName: "full name for id #{id}",
                    simpleName: "simple name for id #{id}")
  result.to_json
end

get "/nsl/services/name/apni/:id/api/apc.json" do |id|
  content_type "application/json"
  result = InApc.new("silly name class",
                     { permalink: [] },
                     "name element for id: #{id}",
                     "action for id: #{id}",
                     true,
                     false,
                     "redundant op name",
                     1,
                     "nsl-name for id: #{id}",
                     1,
                     "nsl-instance for id: #{id}",
                     "999999",
                     "ApcConcept")
  result.to_json
end

get "/nsl/services/reference/apni/:id/api/citation-strings" do
  "Hello World"
end

# http://localhost:9090/nsl/services/instance/apni/666/api/delete?apiKey=test-api-key&reason=Edit
# http://localhost:8080/nsl/services/instance/apni/514039/api/delete?apiKey=d0d1e81d-181c-4ac6-ad75-ddd172594793&reason=Ixxxx
delete "/nsl/services/instance/apni/:id/api/delete" do |id|
  if id == "404"
    [404, { "action" => "delete",
            "errors" => ["The Instance was not found."] }.to_json]
  elsif id == "666"
    [200, { "instance" =>
            { "class" => "au.org.biodiversity.nsl.Instance",
              "_links" =>
                { "permalink" =>
                  { "link" =>
                    "http://localhost:8080/nsl/mapper/boa/instance/apni/514039",
                    "preferred" => true,
                    "resources" => 1 } },
              "instanceType" => "comb. nov.",
              "protologue" => true,
              "citation" =>
              "Britten, J. (1916), Journal of Botany, British and Foreign 54",
              "citationHtml" =>
              "Britten, J. (1916), \
                <i>Journal of Botany, British and Foreign<\u002fi> 54" },
            "action" => "delete",
            "ok" => false,
            "errors" => [
              "There are 1 instances that cite this.",
              "There are 1 instances that say this cites it."
            ] }.to_json]
  elsif id == "5"
    [500]
  else
    [200,
     { "instance" =>
       { "class" =>
         "au.org.biodiversity.nsl.Instance",
         "_links" =>
           { "permalink" =>
             { "link" =>
                 "http://localhost:8080/nsl/mapper/boa/instance/apni/819227",
               "preferred" => true,
               "resources" => 1 } },
         "instanceType" => "taxonomic synonym",
         "protologue" => false,
         "citation" =>
           "Leach, G.J. (1986), A Revision of the Genus Angophora (Myrtaceae).\
           Telopea 2(6)",
         "citationHtml" => "Leach, G.J. (1986), A Revision of the Genus \
         Angophora (Myrtaceae). <i>Telopea</i> 2(6)"},
       "action" => "delete",
       "ok" => true }.to_json]
  end
end

delete "/nsl/services/name/apni/:id/api/delete" do
  content_type "application/json"
  reason = params["reason"]
  case reason
  when /200/
    [200, { "ok" => true }.to_json]
  when /666/
    [200, { "ok" => false, "errors" => ["some silly error"] }.to_json]
  when /404/
    [404, { "action" => "delete", "errors" => ["Object not found."] }.to_json]
  when /5/
    [500]
  else
    [200, { "ok" => true }.to_json]
  end
end

# Dynamic mapping and json-ing methods
class Struct
  def to_map
    map = {}
    members.each { |m| map[m] = self[m] }
    map
  end

  def to_json(*a)
    to_map.to_json(*a)
  end
end

# Mock Reference
class Reference < Struct.new(:class,
                             :_links,
                             :name,
                             :citation,
                             :action,
                             :result)
end

# Mock Name
class Name < Struct.new(:class,
                        :_links,
                        :name_element,
                        :action,
                        :result)
end

# Mock InApc
class InApc < Struct.new(:class,
                         :_links,
                         "nameElement",
                         "action",
                         "inAPC",
                         "excluded",
                         "operation",
                         "nsl_name",
                         "nameNs",
                         "nameId",
                         "taxonNs",
                         "taxonId",
                         "type")
end
