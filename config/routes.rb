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
Rails.application.routes.draw do
  match "/feedback", as: "feedback", to: "feedback#index", via: :get
  match "/ping", as: "ping_service", to: "services#ping", via: :get
  match "services", as: "services", to: "services#index", via: :get

  resources :name_tag_names, only: [:show, :post, :create, :new]
  match "name_tag_names/:name_id/:tag_id",
        as: "delete_name_tag_name",
        to: "name_tag_names#destroy",
        via: :delete

  resources :name_tags, only: [:show]
  resources :comments, only: [:show, :new, :edit, :create, :update, :destroy]

  match "sign_in", as: "start_sign_in", to: "sessions#new", via: :get
  match "retry_sign_in",
        as: "retry_start_sign_in", to: "sessions#retry_new", via: :get
  match "sign_in", as: "sign_in", to: "sessions#create", via: :post
  match "sign_out", as: "sign_out", to: "sessions#destroy", via: :delete
  match "sign_out",
        as: "sign_out_get_for_firefox_bug", to: "sessions#destroy", via: :get
  match "throw_invalid_authenticity_token",
        to: "sessions#throw_invalid_authenticity_token", via: :get

  match "/search", as: "search", to: "search#search", via: :get
  match "/search/index", as: "search_index", to: "search#search", via: :get
  match "/search/tree", as: "tree", to: "search#tree", via: :get
  match "/search/preview", as: "search_preview", to: "search#preview", via: :get
  match "/search/extras/:extras_id",
        as: "search_extras", to: "search#extras", via: :get

  resources :instance_notes,
            only: [:show, :new, :edit, :create, :update, :destroy]

  match "instances/for_name_showing_reference",
        as: "typeahead_for_name_showing_references",
        to: "instances#typeahead_for_name_showing_references",
        via: :get

  match "instances/for_synonymy",
        as: "typeahead_for_synonymy",
        to: "instances#typeahead_for_synonymy",
        via: :get

  match "instances/for_name_showing_reference_to_update_instance",
        as: "typeahead_for_name_showing_references_to_update_instance",
        to: "instances#typeahead_for_name_showing_references_to_update_instance",
        via: :get

  match "instances/create_cited_by",
        as: "create_cited_by", to: "instances#create_cited_by", via: :post
  match "instances/create_cites_and_cited_by",
        as: "create_cites_and_cited_by",
        to: "instances#create_cites_and_cited_by",
        via: :post
  match "instances/:id/reference",
        as: "change_instance_reference",
        to: "instances#change_reference",
        via: :patch
  match "instances/:id/standalone/copy",
        as: "copy_standalone", to: "instances#copy_standalone", via: :post
  resources :instances, only: [:new, :create, :update, :destroy]
  match "instances/:id",
        as: "instance_show",
        to: "instances#show",
        via: :get,
        defaults: { tab: "tab_show_1" }
  match "instances/:id/tab/:tab",
        as: "instance_tab", to: "instances#tab", via: :get

  match "name/refresh/:id", as: "refresh_name", to: "names#refresh", via: :get
  match "name/refresh/children/:id",
        as: "refresh_children_name",
        to: "names#refresh_children",
        via: :get
  match "names/typeaheads/for_unpub_cit/index",
        as: "names_typeahead_for_unpub_cit",
        to: "names/typeaheads/for_unpub_cit#index",
        via: :get

  match "names/typeahead_on_full_name",
        as: "names_typeahead_on_full_name",
        to: "names#typeahead_on_full_name",
        via: :get

  match "names/name_parent_suggestions",
        as: "name_name_parent_suggestions",
        to: "names#name_parent_suggestions",
        via: :get

  match "suggestions/name/hybrid_parent",
        as: "name_hybrid_parent_suggestions",
        to: "names#hybrid_parent_suggestions",
        via: :get

  match "suggestions/name/cultivar_parent",
        as: "name_cultivar_parent_suggestions",
        to: "names#cultivar_parent_suggestions",
        via: :get

  match "suggestions/name/duplicate",
        as: "name_duplicate_suggestions",
        to: "names#duplicate_suggestions",
        via: :get

  match "suggestions/workspace/parent_name",
        as: "workspace_parent_name_suggestions",
        to: "names/typeaheads/for_workspace_parent_name#index",
        via: :get

  match "names/rules",
        as: "name_rules",
        to: "names#rules",
        via: :get

  match "names/new_row/:type",
        as: "name_new_row",
        to: "names#new_row",
        via: :get,
        type: /scientific|phrase|hybrid.*formula|hybrid-formula-unknown-2nd-parent|cultivar-hybrid|cultivar|other/
  match "names/:id/tab/:tab", as: "name_tab", to: "names#tab", via: :get
  match "names/:id/tab/:tab/as/:new_category",
        as: "name_edit_as_category", to: "names#edit_as_category", via: :get
  match "names/:id/copy", as: "name_copy", to: "names#copy", via: :post
  resources :names, only: [:new, :create, :update, :destroy]
  match "names/:id",
        as: "name_show",
        to: "names#show",
        via: :get,
        defaults: { tab: "tab_details" }
  match "names_delete",
        as: "names_deletes",
        to: "names_deletes#confirm",
        via: :delete

  match "authors/typeahead_on_abbrev",
        as: "authors_typeahead_on_abbrev",
        to: "authors#typeahead_on_abbrev", via: :get
  match "authors/typeahead_on_name",
        as: "authors_typeahead_on_name",
        to: "authors#typeahead_on_name", via: :get
  match "authors/typeahead/on_name/duplicate_of/:id",
        as: "authors_typeahead_on_name_duplicate_of_current",
        to: "authors#typeahead_on_name_duplicate_of_current", via: :get
  match "authors/new_row",
        as: "author_new_row", to: "authors#new_row", via: :get
  match "authors/new/:random_id",
        as: "new_author_with_random_id", to: "authors#new", via: :get
  match "authors/:id/tab/:tab", as: "author_tab", to: "authors#tab", via: :get
  resources :authors, only: [:new, :create, :update, :destroy]
  match "authors/:id", as: "author_show",
                       to: "authors#show",
                       via: :get, defaults: { tab: "tab_show_1" }

  match "references/typeahead/on_citation/duplicate_of/:id",
        as: "references_typeahead_on_citation_duplicate_of_current",
        to: "references#typeahead_on_citation_duplicate_of_current", via: :get
  match "references/typeahead/on_citation/exclude/:id",
        as: "references_typeahead_on_citation_with_exclusion",
        to: "references#typeahead_on_citation_with_exclusion", via: :get
  match "references/typeahead/on_citation",
        as: "references_typeahead_on_citation",
        to: "references#typeahead_on_citation", via: :get
  match "references/typeahead/on_citation/for_duplicate/:id",
        as: "references_typeahead_on_citation_for_duplicate",
        to: "references#typeahead_on_citation_for_duplicate", via: :get
  match "references/typeahead/on_citation/for_parent",
        as: "references_typeahead_on_citation_for_parent",
        to: "references#typeahead_on_citation_for_parent", via: :get
  match "references/new_row",
        as: "reference_new_row", to: "references#new_row", via: :get
  resources :references, only: [:new, :create, :update, :destroy]
  match "references/:id",
        as: "reference_show",
        to: "references#show",
        via: :get, defaults: { tab: "tab_show_1" }
  match "references/:id/tab/:tab",
        as: "reference_tab",
        to: "references#tab",
        via: :get,
        defaults: { tab: "tab_show_1" }

  match "/admin", as: "admin", to: "admin#index", via: :get
  match "/admin/throw", as: "throw", to: "admin#throw", via: :get
  match "/admin/db_connections",
        as: "db_connections", to: "admin#db_connections", via: :get

  match "help/index", to: "help#index", via: :get
  match "help/instance_models",
        to: "help#instance_models", as: "instance_models", via: :get
  match "help/ref_type_rules",
        to: "help#ref_type_rules", as: "ref_type_rules", via: :get
  match "help/typeaheads", to: "help#typeaheads", as: "typeaheads", via: :get
  match "history/2016", to: "history#y2016", as: "history_2016", via: :get
  match "history/2015", to: "history#y2015", as: "history_2015", via: :get
  resources :instance_types, only: [:index]

  match "/set_include_common_and_cultivar",
        to: "search#set_include_common_and_cultivar",
        as: "set_include_common_and_cultivar",
        via: :post

  match "trees/ng/:template", as: "tree_ng", to: "trees#ng", via: :get
  match "tree_arrangement/:id/remove_name_placement",
        as: "tree_arrangement_remove_name",
        to: "trees#remove_name_placement", via: :delete
  match "tree_arrangement/:id/place_name",
        as: "tree_arrangement_place_name", to: "trees#place_name", via: [:patch, :post]
  match "trees/workspace/current",
        as: "create_current_workspace",
        to: "trees/workspaces/current#create",
        via: :post

  match "tree_arrangement/:id/update_value",
        as: "tree_arrangement_update_value", to: "trees#update_value", via: :patch

  root to: "search#search"
  match "/*random", to: "search#search", via: [:get, :post, :delete, :patch]
end
