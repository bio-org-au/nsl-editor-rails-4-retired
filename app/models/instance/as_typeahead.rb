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
# Ordering: NSL-1103: added ordering by year.
class Instance::AsTypeahead < Instance
  COLUMNS = " name.full_name, reference.citation, reference.year, " \
            " reference.pages, instance.id, instance.source_system, "\
            " instance_type.name as instance_type_name".freeze

  def self.for_synonymy(terms)
    @name_binds = []
    terms_without_year = terms.gsub(/[0-9]/, "").strip.gsub(/  /, " ")
    return [] if terms_without_year.blank?
    @name_binds.push(" lower(full_name) like lower(?) ")
    @name_binds.push(terms_without_year.tr("*", "%") + "%")
    run_query(terms)
  end

  def self.run_query(terms)
    Instance.select(COLUMNS)
            .joins(:name).where(@name_binds)\
            .joins(:reference).where(reference_binds(terms))\
            .joins(:instance_type)\
            .order("full_name, year").limit(SEARCH_LIMIT)\
            .collect do |i|
      { value: display_value(i), id: i.id }
    end
  end

  def self.display_value(i)
    value = "#{i.full_name} in #{i.citation}:#{i.year}"
    unless i.pages.blank? || i.pages.match(/null - null/)
      value += " [#{i.pages}]"
    end
    unless i.instance_type_name == "secondary reference"
      value += " [#{i.instance_type_name}]"
    end
    value
  end

  def self.reference_binds(terms)
    reference_binds = []
    reference_year = terms.gsub(/[^0-9]/, "")
    if reference_year.present? &&
       reference_year.to_i > 1000 && reference_year.to_i < 3000
      reference_binds.push(" year = ? ")
      reference_binds.push(reference_year)
    end
    reference_binds
  end
end
