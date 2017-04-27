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

# Single instance typeahead search.
class TypeaheadForSynonymyTribusTest < ActiveSupport::TestCase
  def setup
    @ta = Instance::AsTypeahead::ForSynonymy.new("*",
                                                 names(:a_family).id)
  end

  test "instance typeahead for synonymy rank restriction for a tribus" do
    assert @ta.results.size >= 2, "Should be at least 2 synonyms for angophora"
    @rank_names = @ta.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    bulk_test_1
    bulk_test_2
  end

  def bulk_test_1
    %w(Regio Regnum Division Classis Subclassis Superordo Ordo Subordo Genus
       Subgenus Sectio Subsectio Series Subseries Superspecies Species
       Subspecies Nothovarietas Varietas
       Subvarietas Forma Subforma).each do |rank_string|
      assert @rank_names.select { |e| e.match(/\A#{rank_string}\z/) }.empty?,
             "Expect no #{rank_string} to be suggested"
    end
  end

  def bulk_test_2
    assert @rank_names.select { |e| e.match(/\ATribus\z/) }.size == 1,
           "Expect correct number of genera to be suggested"
    %w(Familia Subfamilia Tribus Subtribus).each do |rank_string|
      assert @rank_names.select { |e| e.match(/\A#{rank_string}\z/) }.size == 1,
             "Expect one #{rank_string} to be suggested"
    end
  end
end
