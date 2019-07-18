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
require "test_helper"

# Single controller test.
class ReferencesesCreateFullDateInvMonthTooHighTest < ActionController::TestCase
  tests ReferencesController

  setup do
    @month = 13
    stub_it
  end

  def host
    "localhost:9090"
  end

  def path
    "nsl/services/rest/reference/apni"
  end

  def encoding
    "gzip;q=1.0,deflate;q=0.6,identity;q=0.3"
  end

  def body
    %({"action":"citation-strings",\
       "reference":{"class": "au.org.biodiversity.nsl.Reference", \
                    "_links":{"permalink":{"link":"junk", \
                                           "preferred":true, \
                                           "resources":1}}, \
                              "citation":"the citation", \
                              "citationHtml":"the html citation", \
                              "citationAuthYear":"blah blah"}, \
                    "result":{"citationHtml":"the html citation",\
                              "citation":"the citation"}})
  end

  def stub_it
    stub_request(:get, %r{http://#{host}/#{path}/\d+/api/citation-strings})
      .with(
        headers: { "Accept" => "*/*",
                   "Accept-Encoding" => encoding,
                   "User-Agent" => "Ruby" }
      )
      .to_return(status: 200, body: body, headers: {})
  end

  test "create reference full date invalid month too high" do
    @request.headers["Accept"] = "application/javascript"
    assert_no_difference("Reference.count") do
      post(:create,
           { reference: { "ref_type_id" => ref_types(:book),
                          "title" => "Some book",
                          "author_id" => authors(:dash),
                          "author_typeahead" => "-",
                          "published" => true,
                          "parent_typeahead" => @parent_typeahead,
                          "ref_author_role_id" => ref_author_roles(:author),
                          "day" => "30",
                          "month" => @month,
                          "year" => "1988" } },
           username: "fred",
           user_full_name: "Fred Jones",
           groups: ["edit"])
      assert_match(/Error: Month #{@month} is above the range 1-12/,
                   response.body.to_s,
                   "Missing or incorrect error message")
    end
  end
end
