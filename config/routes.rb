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
Rails.application.routes.draw do

  match '/ping', as: "ping_service", to: "services#ping", via: :get
  match 'services', as: "services", to: "services#index", via: :get

  resources :name_tag_names, only: [:show,:post,:create,:new]
  match 'name_tag_names/:name_id/:tag_id', as: 'delete_name_tag_name', to: "name_tag_names#destroy", via: :delete  

  resources :name_tags, only: [:show]
  resources :comments, only: [:show, :new, :edit, :create, :update, :destroy]

  ###############  TRee controller paths - need to be moved somewhere more appropriate in this file

  match 'trees/ng/:template', as: 'tree_ng', to: 'trees#ng', via: :get

  ###############  TRee controller paths - need to be moved somewhere more appropriate in this file

  match 'sign_in', as: "start_sign_in", to: "sessions#new", via: :get
  match 'retry_sign_in', as: "retry_start_sign_in", to: "sessions#retry_new", via: :get
  match 'sign_in', as: "sign_in", to: 'sessions#create', via: :post
  match 'sign_out', as: "sign_out", to: "sessions#destroy", via: :delete
  match 'sign_out', as: "sign_out_get_for_firefox_bug", to: "sessions#destroy", via: :get
  match 'throw_invalid_authenticity_token', to: "sessions#throw_invalid_authenticity_token", via: :get

  match 'search/name/with/instances/:query',
         as: 'search_name_with_instances',
         to: 'search#index',
         via: :get,
         defaults: { query_on: 'instance',
                     query_field: 'name-id' }

  match '/search', as: "search", to: "search#index", via: :get

  resources :instance_notes, only: [:show, :new, :edit, :create, :update, :destroy]

  match 'instances/for_name_showing_reference',
        as: "typeahead_for_name_showing_references",
        to: "instances#typeahead_for_name_showing_references",
        via: :get

  match 'instances/for_synonymy',
        as: "typeahead_for_synonymy",
        to: "instances#typeahead_for_synonymy",
        via: :get

  match 'instances/for_name_showing_reference_to_update_instance',
        as: "typeahead_for_name_showing_references_to_update_instance",
        to: "instances#typeahead_for_name_showing_references_to_update_instance",
        via: :get

  match 'instances/:id/tab/:tab', as: "instance_tab", to: "instances#show", via: :get
  match 'instances/create_cited_by', as: 'create_cited_by', to: "instances#create_cited_by", via: :post
  match 'instances/create_cites_and_cited_by', as: 'create_cites_and_cited_by', to: "instances#create_cites_and_cited_by", via: :post
  match 'instances/:id/reference', as: 'change_instance_reference', to: "instances#change_reference", via: :patch
  match 'instances/:id/standalone/copy', as: "copy_standalone", to: "instances#copy_standalone" , via: :post
  resources :instances, only: [:show, :new, :create, :update, :destroy]

  match 'name/refresh/:id', as: "refresh_name", to: "names#refresh", via: :get
  match 'names/typeahead_on_full_name', 
         as: "names_typeahead_on_full_name", 
         to: "names#typeahead_on_full_name", 
         via: :get

  match 'names/name_parent_suggestions', 
         as: "name_name_parent_suggestions", 
         to: "names#name_parent_suggestions", 
         via: :get

  match 'suggestions/name/hybrid_parent',
         as: "name_hybrid_parent_suggestions", 
         to: "names#hybrid_parent_suggestions", 
         via: :get

  match 'suggestions/name/cultivar_parent',
         as: "name_cultivar_parent_suggestions", 
         to: "names#cultivar_parent_suggestions", 
         via: :get

  match 'suggestions/name/duplicate',
        as: "name_duplicate_suggestions",
        to: "names#duplicate_suggestions",
        via: :get

  match 'names/rules',
         as: "name_rules", 
         to: "names#rules", 
         via: :get

  match 'names/new_row/:type', as: 'name_new_row', to: "names#new_row", via: :get, 
         type: /scientific|hybrid.*formula|hybrid-formula-unknown-2nd-parent|cultivar-hybrid|cultivar|other/ 
  match 'names/:id/tab/:tab', as: "name_tab", to: "names#show", via: :get
  match 'names/:id/tab/:tab/as/:new_category', as: "name_edit_as_category", to: "names#edit_as_category", via: :get
  match 'names/:id/copy', as: "name_copy", to: "names#copy", via: :post
  resources :names, only: [:show, :new, :create, :update, :destroy]
  match 'names_delete', as: "names_deletes", to: "names_deletes#confirm", via: :delete

  match 'authors/typeahead_on_abbrev', as: "authors_typeahead_on_abbrev", to: "authors#typeahead_on_abbrev", via: :get
  match 'authors/typeahead_on_name', as: "authors_typeahead_on_name", to: "authors#typeahead_on_name", via: :get
  match 'authors/typeahead/on_name/duplicate_of/:id', as: "authors_typeahead_on_name_duplicate_of_current", to: "authors#typeahead_on_name_duplicate_of_current", via: :get
  match 'authors/:id/tab/:tab', as: "author_tab", to: "authors#show", via: :get
  match 'authors/new_row', as: 'author_new_row', to: "authors#new_row", via: :get
  match 'authors/new/:random_id', as: 'new_author_with_random_id', to: "authors#new", via: :get
  resources :authors, only: [:show, :new, :create, :update, :destroy]

  match 'references/typeahead/on_citation/duplicate_of/:id', as: "references_typeahead_on_citation_duplicate_of_current", to: "references#typeahead_on_citation_duplicate_of_current", via: :get
  match 'references/typeahead/on_citation', as: "references_typeahead_on_citation", to: "references#typeahead_on_citation", via: :get
  match 'references/typeahead/on_citation/for_duplicate/:id', as: "references_typeahead_on_citation_for_duplicate", to: "references#typeahead_on_citation_for_duplicate", via: :get
  match 'references/typeahead/on_citation/for_parent', as: "references_typeahead_on_citation_for_parent", to: "references#typeahead_on_citation_for_parent", via: :get
  match 'references/:id/tab/:tab', as: "reference_tab", to: "references#show", via: :get
  match 'references/new_row', as: 'reference_new_row', to: "references#new_row", via: :get
  resources :references, only: [:show, :new, :create, :update, :destroy]

  match '/admin', as: "admin", to: "admin#index", via: :get
  match '/admin/throw', as: "throw", to: "admin#throw", via: :get

  match 'help/index', to: "help#index", via: :get
  match 'help/history', to: "help#history", as: 'history', via: :get
  match 'help/instance_models', to: "help#instance_models", as: 'instance_models', via: :get
  match 'help/ref_type_rules', to: "help#ref_type_rules", as: 'ref_type_rules', via: :get
  match 'help/typeaheads', to: "help#typeaheads", as: 'typeaheads', via: :get

  root to: "search#index"
  match '/*random', to: "search#index", via: [:get,:post,:delete,:patch]
  
end
