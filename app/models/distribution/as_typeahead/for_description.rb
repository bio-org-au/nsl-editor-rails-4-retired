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
# Return array of instances based primarily on full_name
# but additionally on reference.year.
#
# Take a string of search terms like "podolepis jaceoides 1957".
# Match the year component against reference.year and the
# non-year component against name.full_name in a join
# on instance.
# Can also handle strings like:
#   '1957 podolepis jaceoides'
#   'podolepis 1957 jaceoides'
#
# But disordered name fragments, like
#   'jac podolepis'
# do not work because the text part
# is not currently broken into independently
# matched fragments.
#
class Distribution::AsTypeahead::ForDescription
  attr_reader :results
  COLUMNS = " id, description, region, is_doubtfully_naturalised, is_extinct, is_native, is_naturalised "
  SEARCH_LIMIT = 20

  def initialize(term)
    @term = term&.downcase
    query()
  end

  def query()
    @results = Distribution.display_order
    if (@term)
      @results = @results.select { | dist | dist.description.downcase.include?(@term)}
    end
  end
end