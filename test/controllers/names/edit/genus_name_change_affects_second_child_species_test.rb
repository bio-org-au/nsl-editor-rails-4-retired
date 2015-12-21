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
require 'test_helper'

class GenusNameChangeAffectsSecondChildSpeciesAndSubspeciesTest < ActionController::TestCase
  tests NamesController

  test 'genus name change affects second child species and subspecies' do
    genus = names(:acacia)
    species = names(:another_species)
    subspecies = names(:hybrid_formula)
    @request.headers['Accept'] = 'application/javascript'
    post(:update, { name: { 'full_name' => 'newfullname'}, 
                    id: genus.id
                  },
                  username: 'fred', user_full_name: 'Fred Jones', groups: ['edit'])
    assert_response :success
    sleep(2) # to allow for the asynch job
    species_afterwards = Name.find(species.id)
    assert species.full_name != species_afterwards.full_name, "The genus's name has changed and this should affect the species's name."
    subspecies_afterwards = Name.find(subspecies.id)
    assert subspecies.full_name != subspecies_afterwards.full_name, "The genus's name has changed and this should affect the subspecies's name."
  end
end

