# encoding: UTF-8
#
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

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "unaccent"

  create_table "namespace", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0, null: false
    t.string  "name",                                    null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_eq2y9mghytirkcofquanv5frf", :unique => true
    t.index ["rdf_id"], :name => "namespace_rdfid"
  end

  create_table "author", force: true do |t|
    t.integer  "lock_version",     limit: 8,    default: 0,     null: false
    t.string   "abbrev",           limit: 100
    t.datetime "created_at",                                    null: false
    t.string   "created_by",                                    null: false
    t.string   "date_range",       limit: 50
    t.integer  "duplicate_of_id",  limit: 8
    t.string   "full_name"
    t.string   "ipni_id",          limit: 50
    t.string   "name"
    t.integer  "namespace_id",     limit: 8,                    null: false
    t.string   "notes",            limit: 1000
    t.integer  "source_id",        limit: 8
    t.string   "source_id_string", limit: 100
    t.string   "source_system",    limit: 50
    t.boolean  "trash",                         default: false, null: false
    t.datetime "updated_at",                                    null: false
    t.string   "updated_by",                                    null: false
    t.boolean  "valid_record",                  default: false, null: false
    t.index ["abbrev"], :name => "author_abbrev_index"
    t.index ["name"], :name => "author_name_index"
    t.index ["namespace_id", "source_id", "source_system"], :name => "auth_source_index"
    t.index ["source_id_string"], :name => "auth_source_string_index"
    t.index ["source_system"], :name => "auth_system_index"
    t.foreign_key ["duplicate_of_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_6a4p11f1bt171w09oo06m0wag"
    t.foreign_key ["namespace_id"], "namespace", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_p0ysrub11cm08xnhrbrfrvudh"
  end

  create_table "instance_type", force: true do |t|
    t.integer "lock_version",       limit: 8,  default: 0,     null: false
    t.boolean "citing",                        default: false, null: false
    t.boolean "deprecated",                    default: false, null: false
    t.boolean "doubtful",                      default: false, null: false
    t.boolean "misapplied",                    default: false, null: false
    t.string  "name",                                          null: false
    t.boolean "nomenclatural",                 default: false, null: false
    t.boolean "primary_instance",              default: false, null: false
    t.boolean "pro_parte",                     default: false, null: false
    t.boolean "protologue",                    default: false, null: false
    t.boolean "relationship",                  default: false, null: false
    t.boolean "secondary_instance",            default: false, null: false
    t.integer "sort_order",                    default: 0,     null: false
    t.boolean "standalone",                    default: false, null: false
    t.boolean "synonym",                       default: false, null: false
    t.boolean "taxonomic",                     default: false, null: false
    t.boolean "unsourced",                     default: false, null: false
    t.text    "description_html"
    t.string  "rdf_id",             limit: 50
    t.index ["name"], :name => "uk_j5337m9qdlirvd49v4h11t1lk", :unique => true
    t.index ["rdf_id"], :name => "instance_type_rdfid"
  end

  create_table "name_group", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0, null: false
    t.string  "name",             limit: 50
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_5185nbyw5hkxqyyqgylfn2o6d", :unique => true
    t.index ["rdf_id"], :name => "name_group_rdfid"
  end

  create_table "name_rank", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0,     null: false
    t.string  "abbrev",           limit: 20,                 null: false
    t.boolean "deprecated",                  default: false, null: false
    t.boolean "has_parent",                  default: false, null: false
    t.boolean "italicize",                   default: false, null: false
    t.boolean "major",                       default: false, null: false
    t.string  "name",             limit: 50,                 null: false
    t.integer "name_group_id",    limit: 8,                  null: false
    t.integer "parent_rank_id",   limit: 8
    t.integer "sort_order",                  default: 0,     null: false
    t.boolean "visible_in_name",             default: true,  null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["rdf_id"], :name => "name_rank_rdfid"
    t.foreign_key ["name_group_id"], "name_group", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_p3lpayfbl9s3hshhoycfj82b9"
    t.foreign_key ["parent_rank_id"], "name_rank", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_r67um91pujyfrx7h1cifs3cmb"
  end

  create_table "name_status", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0,     null: false
    t.boolean "display",                     default: true,  null: false
    t.string  "name",             limit: 50
    t.integer "name_group_id",    limit: 8,                  null: false
    t.integer "name_status_id",   limit: 8
    t.boolean "nom_illeg",                   default: false, null: false
    t.boolean "nom_inval",                   default: false, null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_se7crmfnhjmyvirp3p9hiqerx", :unique => true
    t.index ["rdf_id"], :name => "name_status_rdfid"
    t.foreign_key ["name_group_id"], "name_group", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_swotu3c2gy1hp8f6ekvuo7s26"
    t.foreign_key ["name_status_id"], "name_status", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_g4o6xditli5a0xrm6eqc6h9gw"
  end

  create_table "name_category", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0, null: false
    t.string  "name",             limit: 50,             null: false
    t.integer "sort_order",                  default: 0, null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_rxqxoenedjdjyd4x7c98s59io", :unique => true
    t.index ["rdf_id"], :name => "name_category_rdfid"
  end

  create_table "name_type", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0,     null: false
    t.boolean "autonym",                     default: false, null: false
    t.string  "connector",        limit: 1
    t.boolean "cultivar",                    default: false, null: false
    t.boolean "formula",                     default: false, null: false
    t.boolean "hybrid",                      default: false, null: false
    t.string  "name",                                        null: false
    t.integer "name_category_id", limit: 8,                  null: false
    t.integer "name_group_id",    limit: 8,                  null: false
    t.boolean "scientific",                  default: false, null: false
    t.integer "sort_order",                  default: 0,     null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.boolean "deprecated",                  default: false, null: false
    t.index ["name"], :name => "uk_314uhkq8i7r46050kd1nfrs95", :unique => true
    t.index ["rdf_id"], :name => "name_type_rdfid"
    t.foreign_key ["name_category_id"], "name_category", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_10d0jlulq2woht49j5ccpeehu"
    t.foreign_key ["name_group_id"], "name_group", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_5r3o78sgdbxsf525hmm3t44gv"
  end

  create_table "why_is_this_here", force: true do |t|
    t.integer "lock_version", limit: 8,  default: 0, null: false
    t.string  "name",         limit: 50,             null: false
    t.integer "sort_order",              default: 0, null: false
    t.index ["name"], :name => "uk_sv1q1i7xve7xgmkwvmdbeo1mb", :unique => true
  end

  create_table "name", force: true do |t|
    t.integer  "lock_version",          limit: 8,    default: 0,     null: false
    t.integer  "author_id",             limit: 8
    t.integer  "base_author_id",        limit: 8
    t.datetime "created_at",                                         null: false
    t.string   "created_by",            limit: 50,                   null: false
    t.integer  "duplicate_of_id",       limit: 8
    t.integer  "ex_author_id",          limit: 8
    t.integer  "ex_base_author_id",     limit: 8
    t.string   "full_name",             limit: 512
    t.string   "full_name_html",        limit: 2048
    t.string   "name_element"
    t.integer  "name_rank_id",          limit: 8,                    null: false
    t.integer  "name_status_id",        limit: 8,                    null: false
    t.integer  "name_type_id",          limit: 8,                    null: false
    t.integer  "namespace_id",          limit: 8,                    null: false
    t.boolean  "orth_var",                           default: false, null: false
    t.integer  "parent_id",             limit: 8
    t.integer  "sanctioning_author_id", limit: 8
    t.integer  "second_parent_id",      limit: 8
    t.string   "simple_name",           limit: 250
    t.string   "simple_name_html",      limit: 2048
    t.integer  "source_dup_of_id",      limit: 8
    t.integer  "source_id",             limit: 8
    t.string   "source_id_string",      limit: 100
    t.string   "source_system",         limit: 50
    t.string   "status_summary",        limit: 50
    t.boolean  "trash",                              default: false, null: false
    t.datetime "updated_at",                                         null: false
    t.string   "updated_by",            limit: 50,                   null: false
    t.boolean  "valid_record",                       default: false, null: false
    t.integer  "why_is_this_here_id",   limit: 8
    t.string   "verbatim_rank",         limit: 50
    #t.index :name => "name_lower_f_unaccent_full_name_like", :expression => "lower(f_unaccent((full_name)::text))"
    t.index ["author_id"], :name => "name_author_index"
    t.index ["base_author_id"], :name => "name_baseauthor_index"
    t.index ["ex_author_id"], :name => "name_exauthor_index"
    t.index ["ex_base_author_id"], :name => "name_exbaseauthor_index"
    t.index ["full_name"], :name => "lower_full_name", :case_sensitive => false
    t.index ["full_name"], :name => "name_full_name_index"
    t.index ["name_element"], :name => "name_name_element_index"
    t.index ["name_rank_id"], :name => "name_rank_index"
    t.index ["name_status_id"], :name => "name_status_index"
    t.index ["name_type_id"], :name => "name_type_index"
    t.index ["namespace_id", "source_id", "source_system"], :name => "name_source_index"
    t.index ["sanctioning_author_id"], :name => "name_sanctioningauthor_index"
    t.index ["simple_name"], :name => "name_simple_name_index"
    t.index ["source_id_string"], :name => "name_source_string_index"
    t.index ["source_system"], :name => "name_system_index"
    t.index ["why_is_this_here_id"], :name => "name_whyisthishere_index"
    t.foreign_key ["author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_airfjupm6ohehj1lj82yqkwdx"
    t.foreign_key ["base_author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_coqxx3ewgiecsh3t78yc70b35"
    t.foreign_key ["duplicate_of_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_3pqdqa03w5c6h4yyrrvfuagos"
    t.foreign_key ["ex_author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_sgvxmyj7r9g4wy9c4hd1yn4nu"
    t.foreign_key ["ex_base_author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_rp659tjcxokf26j8551k6an2y"
    t.foreign_key ["name_rank_id"], "name_rank", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_sk2iikq8wla58jeypkw6h74hc"
    t.foreign_key ["name_status_id"], "name_status", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_5fpm5u0ukiml9nvmq14bd7u51"
    t.foreign_key ["name_type_id"], "name_type", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_bcef76k0ijrcquyoc0yxehxfp"
    t.foreign_key ["namespace_id"], "namespace", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_156ncmx4599jcsmhh5k267cjv"
    t.foreign_key ["parent_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_dd33etb69v5w5iah1eeisy7yt"
    t.foreign_key ["sanctioning_author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_ai81l07vh2yhmthr3582igo47"
    t.foreign_key ["second_parent_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_5gp2lfblqq94c4ud3340iml0l"
    t.foreign_key ["why_is_this_here_id"], "why_is_this_here", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_dqhn53mdh0n77xhsw7l5dgd38"
  end

  create_table "language", force: true do |t|
    t.integer "lock_version", limit: 8,  default: 0, null: false
    t.string  "iso6391code",  limit: 2
    t.string  "iso6393code",  limit: 3,              null: false
    t.string  "name",         limit: 50,             null: false
    t.index ["iso6391code"], :name => "uk_hghw87nl0ho38f166atlpw2hy", :unique => true
    t.index ["iso6393code"], :name => "uk_rpsahneqboogcki6p1bpygsua", :unique => true
    t.index ["name"], :name => "uk_g8hr207ijpxlwu10pewyo65gv", :unique => true
  end

  create_table "ref_author_role", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0, null: false
    t.string  "name",                                    null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_l95kedbafybjpp3h53x8o9fke", :unique => true
    t.index ["rdf_id"], :name => "ref_author_role_rdfid"
  end

  create_table "ref_type", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0,     null: false
    t.string  "name",             limit: 50,                 null: false
    t.integer "parent_id",        limit: 8
    t.boolean "parent_optional",             default: false, null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_4fp66uflo7rgx59167ajs0ujv", :unique => true
    t.index ["rdf_id"], :name => "ref_type_rdfid"
    t.foreign_key ["parent_id"], "ref_type", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_51alfoe7eobwh60yfx45y22ay"
  end

  create_table "reference", force: true do |t|
    t.integer  "lock_version",       limit: 8,    default: 0,     null: false
    t.string   "abbrev_title",       limit: 2000
    t.integer  "author_id",          limit: 8,                    null: false
    t.string   "bhl_url",            limit: 4000
    t.string   "citation",           limit: 512
    t.string   "citation_html",      limit: 512
    t.datetime "created_at",                                      null: false
    t.string   "created_by",                                      null: false
    t.string   "display_title",      limit: 2000,                 null: false
    t.string   "doi"
    t.integer  "duplicate_of_id",    limit: 8
    t.string   "edition",            limit: 50
    t.string   "isbn",               limit: 16
    t.string   "issn",               limit: 16
    t.integer  "language_id",        limit: 8,                    null: false
    t.integer  "namespace_id",       limit: 8,                    null: false
    t.string   "notes",              limit: 1000
    t.string   "pages"
    t.integer  "parent_id",          limit: 8
    t.string   "publication_date",   limit: 50
    t.boolean  "published",                       default: false, null: false
    t.string   "published_location", limit: 50
    t.string   "publisher",          limit: 100
    t.integer  "ref_author_role_id", limit: 8,                    null: false
    t.integer  "ref_type_id",        limit: 8,                    null: false
    t.integer  "source_id",          limit: 8
    t.string   "source_id_string",   limit: 100
    t.string   "source_system",      limit: 50
    t.string   "title",              limit: 2000,                 null: false
    t.string   "tl2",                limit: 30
    t.boolean  "trash",                           default: false, null: false
    t.datetime "updated_at",                                      null: false
    t.string   "updated_by",         limit: 1000,                 null: false
    t.boolean  "valid_record",                    default: false, null: false
    t.string   "verbatim_author",    limit: 1000
    t.string   "verbatim_citation",  limit: 2000
    t.string   "verbatim_reference", limit: 1000
    t.string   "volume",             limit: 50
    t.integer  "year"
    t.index ["author_id"], :name => "reference_author_index"
    t.index ["doi"], :name => "uk_kqwpm0crhcq4n9t9uiyfxo2df", :unique => true
    t.index ["namespace_id", "source_id", "source_system"], :name => "ref_source_index"
    t.index ["parent_id"], :name => "reference_parent_index"
    t.index ["ref_author_role_id"], :name => "reference_authorrole_index"
    t.index ["ref_type_id"], :name => "reference_type_index"
    t.index ["source_id_string"], :name => "ref_source_string_index"
    t.index ["source_system"], :name => "ref_system_index"
    t.foreign_key ["author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_p8lhsoo01164dsvvwxob0w3sp"
    t.foreign_key ["duplicate_of_id"], "reference", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_3min66ljijxavb0fjergx5dpm"
    t.foreign_key ["language_id"], "language", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_1qx84m8tuk7vw2diyxfbj5r2n"
    t.foreign_key ["namespace_id"], "namespace", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_am2j11kvuwl19gqewuu18gjjm"
    t.foreign_key ["parent_id"], "reference", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_cr9avt4miqikx4kk53aflnnkd"
    t.foreign_key ["ref_author_role_id"], "ref_author_role", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_a98ei1lxn89madjihel3cvi90"
    t.foreign_key ["ref_type_id"], "ref_type", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_dm9y4p9xpsc8m7vljbohubl7x"
  end

  create_table "instance", force: true do |t|
    t.integer  "lock_version",         limit: 8,    default: 0,     null: false
    t.string   "bhl_url",              limit: 4000
    t.integer  "cited_by_id",          limit: 8
    t.integer  "cites_id",             limit: 8
    t.datetime "created_at",                                        null: false
    t.string   "created_by",           limit: 50,                   null: false
    t.boolean  "draft",                             default: false, null: false
    t.integer  "instance_type_id",     limit: 8,                    null: false
    t.integer  "name_id",              limit: 8,                    null: false
    t.integer  "namespace_id",         limit: 8,                    null: false
    t.string   "nomenclatural_status", limit: 50
    t.string   "page"
    t.string   "page_qualifier"
    t.integer  "parent_id",            limit: 8
    t.integer  "reference_id",         limit: 8,                    null: false
    t.integer  "source_id",            limit: 8
    t.string   "source_id_string",     limit: 100
    t.string   "source_system",        limit: 50
    t.boolean  "trash",                             default: false, null: false
    t.datetime "updated_at",                                        null: false
    t.string   "updated_by",           limit: 1000,                 null: false
    t.boolean  "valid_record",                      default: false, null: false
    t.string   "verbatim_name_string"
    t.index ["cited_by_id"], :name => "instance_citedby_index"
    t.index ["cites_id"], :name => "instance_cites_index"
    t.index ["instance_type_id"], :name => "instance_instancetype_index"
    t.index ["name_id"], :name => "instance_name_index"
    t.index ["namespace_id", "source_id", "source_system"], :name => "instance_source_index"
    t.index ["parent_id"], :name => "instance_parent_index"
    t.index ["reference_id"], :name => "instance_reference_index"
    t.index ["source_id_string"], :name => "instance_source_string_index"
    t.index ["source_system"], :name => "instance_system_index"
    t.foreign_key ["cited_by_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_pr2f6peqhnx9rjiwkr5jgc5be"
    t.foreign_key ["cites_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_30enb6qoexhuk479t75apeuu5"
    t.foreign_key ["instance_type_id"], "instance_type", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_o80rrtl8xwy4l3kqrt9qv0mnt"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_gdunt8xo68ct1vfec9c6x5889"
    t.foreign_key ["namespace_id"], "namespace", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_gtkjmbvk6uk34fbfpy910e7t6"
    t.foreign_key ["parent_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_hb0xb97midopfgrm2k5fpe3p1"
    t.foreign_key ["reference_id"], "reference", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_lumlr5avj305pmc4hkjwaqk45"
  end

  create_table "comment", force: true do |t|
    t.integer  "lock_version", limit: 8,  default: 0, null: false
    t.integer  "author_id",    limit: 8
    t.datetime "created_at",                          null: false
    t.string   "created_by",   limit: 50,             null: false
    t.integer  "instance_id",  limit: 8
    t.integer  "name_id",      limit: 8
    t.integer  "reference_id", limit: 8
    t.text     "text",                                null: false
    t.datetime "updated_at",                          null: false
    t.string   "updated_by",   limit: 50,             null: false
    t.index ["author_id"], :name => "comment_author_index"
    t.index ["instance_id"], :name => "comment_instance_index"
    t.index ["name_id"], :name => "comment_name_index"
    t.index ["reference_id"], :name => "comment_reference_index"
    t.foreign_key ["author_id"], "author", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_9aq5p2jgf17y6b38x5ayd90oc"
    t.foreign_key ["instance_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_6oqj6vquqc33cyawn853hfu5g"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_h9t5eaaqhnqwrc92rhryyvdcf"
    t.foreign_key ["reference_id"], "reference", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_3tfkdcmf6rg6hcyiu8t05er7x"
  end

  create_table "db_version", force: true do |t|
    t.integer "version", null: false
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "lock_version", limit: 8,                             default: 0, null: false
    t.decimal  "attempts",                  precision: 19, scale: 2
    t.datetime "created_at",                                                     null: false
    t.datetime "failed_at"
    t.text     "handler"
    t.text     "last_error"
    t.datetime "locked_at"
    t.string   "locked_by",    limit: 4000
    t.decimal  "priority",                  precision: 19, scale: 2
    t.string   "queue",        limit: 4000
    t.datetime "run_at"
    t.datetime "updated_at",                                                     null: false
  end

  create_table "external_ref", force: true do |t|
    t.integer "lock_version",         limit: 8,                           default: 0, null: false
    t.string  "external_id",          limit: 50,                                      null: false
    t.string  "external_id_supplier", limit: 50,                                      null: false
    t.integer "instance_id",          limit: 8,                                       null: false
    t.integer "name_id",              limit: 8,                                       null: false
    t.string  "object_type",          limit: 50
    t.decimal "original_provider",               precision: 19, scale: 2
    t.integer "reference_id",         limit: 8,                                       null: false
    t.foreign_key ["instance_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_4g2i2qry4941xmqijgeo8ns2h"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_bu7q5itmt7w7q1bex049xvac7"
    t.foreign_key ["reference_id"], "reference", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_f7igpcpvgcmdfb7v3bgjluqsf"
  end

  create_table "help_topic", force: true do |t|
    t.integer  "lock_version",   limit: 8,    default: 0,     null: false
    t.datetime "created_at",                                  null: false
    t.string   "created_by",     limit: 4000,                 null: false
    t.text     "marked_up_text",                              null: false
    t.string   "name",           limit: 4000,                 null: false
    t.integer  "sort_order",                  default: 0,     null: false
    t.boolean  "trash",                       default: false, null: false
    t.datetime "updated_at",                                  null: false
    t.string   "updated_by",     limit: 4000,                 null: false
  end

  create_table "id_mapper", force: true do |t|
    t.integer "from_id",      limit: 8,  null: false
    t.integer "namespace_id", limit: 8,  null: false
    t.string  "system",       limit: 20, null: false
    t.integer "to_id",        limit: 8
    t.index ["from_id", "namespace_id", "system"], :name => "id_mapper_from_index"
    t.index ["to_id", "from_id"], :name => "unique_from_id", :unique => true
    t.foreign_key ["namespace_id"], "namespace", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_qiy281xsleyhjgr0eu1sboagm"
  end

  create_table "instance_note_key", force: true do |t|
    t.integer "lock_version",     limit: 8,  default: 0,     null: false
    t.boolean "deprecated",                  default: false, null: false
    t.string  "name",                                        null: false
    t.integer "sort_order",                  default: 0,     null: false
    t.text    "description_html"
    t.string  "rdf_id",           limit: 50
    t.index ["name"], :name => "uk_a0justk7c77bb64o6u1riyrlh", :unique => true
    t.index ["rdf_id"], :name => "instance_note_key_rdfid"
  end

  create_table "instance_note", force: true do |t|
    t.integer  "lock_version",         limit: 8,    default: 0,     null: false
    t.datetime "created_at",                                        null: false
    t.string   "created_by",           limit: 50,                   null: false
    t.integer  "instance_id",          limit: 8,                    null: false
    t.integer  "instance_note_key_id", limit: 8,                    null: false
    t.integer  "namespace_id",         limit: 8,                    null: false
    t.integer  "source_id",            limit: 8
    t.string   "source_id_string",     limit: 100
    t.string   "source_system",        limit: 50
    t.boolean  "trash",                             default: false, null: false
    t.datetime "updated_at",                                        null: false
    t.string   "updated_by",           limit: 50,                   null: false
    t.string   "value",                limit: 4000,                 null: false
    t.index ["instance_id"], :name => "note_instance_index"
    t.index ["instance_note_key_id"], :name => "note_key_index"
    t.index ["namespace_id", "source_id", "source_system"], :name => "note_source_index"
    t.index ["source_id_string"], :name => "note_source_string_index"
    t.index ["source_system"], :name => "note_system_index"
    t.foreign_key ["instance_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_bw41122jb5rcu8wfnog812s97"
    t.foreign_key ["instance_note_key_id"], "instance_note_key", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_he1t3ug0o7ollnk2jbqaouooa"
    t.foreign_key ["namespace_id"], "namespace", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_f6s94njexmutjxjv8t5dy1ugt"
  end

  create_table "locale", force: true do |t|
    t.integer "lock_version",       limit: 8,  default: 0, null: false
    t.string  "locale_name_string", limit: 50,             null: false
    t.index ["locale_name_string"], :name => "uk_qjkskvl9hx0w78truoyq9teju", :unique => true
  end

  create_table "name_part", force: true do |t|
    t.integer "lock_version",        limit: 8,  default: 0, null: false
    t.integer "name_id",             limit: 8,              null: false
    t.integer "preceding_name_id",   limit: 8,              null: false
    t.string  "preceding_name_type", limit: 50,             null: false
    t.index ["name_id"], :name => "name_part_name_id_ndx"
    t.index ["preceding_name_type"], :name => "preceding_name_type_index"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_s13ituehdpf6uh859umme7g1j"
    t.foreign_key ["preceding_name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_pj38oewhgjq8rp08fc9cviteu"
  end

  create_table "name_tag", force: true do |t|
    t.string  "name",                               null: false
    t.integer "lock_version", limit: 8, default: 0, null: false
    t.index ["name"], :name => "uk_o4su6hi7vh0yqs4c1dw0fsf1e", :unique => true
  end

  create_table "name_tag_name", primary_key: "name_id", force: true do |t|
    t.integer  "tag_id",     limit: 8, null: false
    t.datetime "created_at",           null: false
    t.string   "created_by",           null: false
    t.datetime "updated_at",           null: false
    t.string   "updated_by",           null: false
    t.index ["name_id"], :name => "name_tag_name_index"
    t.index ["tag_id"], :name => "name_tag_tag_index"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_22wdc2pxaskytkgpdgpyok07n"
    t.foreign_key ["tag_id"], "name_tag", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_2uiijd73snf6lh5s6a82yjfin"
  end

  create_table "tree_event", force: true do |t|
    t.integer  "lock_version", limit: 8, default: 0, null: false
    t.string   "auth_user",                          null: false
    t.string   "note"
    t.datetime "time_stamp",                         null: false
  end

  create_table "tree_uri_ns", force: true do |t|
    t.integer "lock_version",           limit: 8,  default: 0, null: false
    t.string  "description"
    t.integer "id_mapper_namespace_id", limit: 8
    t.string  "id_mapper_system"
    t.string  "label",                  limit: 20,             null: false
    t.string  "owner_uri_id_part"
    t.integer "owner_uri_ns_part_id",   limit: 8
    t.string  "title"
    t.string  "uri"
    t.index ["label"], :name => "idx_tree_uri_ns_label"
    t.index ["label"], :name => "uk_5smmen5o34hs50jxd247k81ia", :unique => true
    t.index ["uri"], :name => "idx_tree_uri_ns_uri"
    t.index ["uri"], :name => "uk_70p0ys3l5v6s9dqrpjr3u3rrf", :unique => true
    t.foreign_key ["owner_uri_ns_part_id"], "tree_uri_ns", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_q9k8he941kvl07j2htmqxq35v"
  end

  create_table "tree_node", force: true do |t|
    t.integer "lock_version",            limit: 8,    default: 0, null: false
    t.integer "checked_in_at_id",        limit: 8
    t.string  "internal_type",                                    null: false
    t.string  "literal",                 limit: 4096
    t.string  "name_uri_id_part"
    t.integer "name_uri_ns_part_id",     limit: 8
    t.integer "next_node_id",            limit: 8
    t.integer "prev_node_id",            limit: 8
    t.integer "replaced_at_id",          limit: 8
    t.string  "resource_uri_id_part"
    t.integer "resource_uri_ns_part_id", limit: 8
    t.integer "tree_arrangement_id",     limit: 8
    t.string  "is_synthetic",            limit: nil,              null: false
    t.string  "taxon_uri_id_part"
    t.integer "taxon_uri_ns_part_id",    limit: 8
    t.string  "type_uri_id_part"
    t.integer "type_uri_ns_part_id",     limit: 8,                null: false
    t.integer "name_id",                 limit: 8
    t.integer "instance_id",             limit: 8
    t.index ["instance_id", "tree_arrangement_id"], :name => "idx_tree_node_instance_id_in"
    t.index ["instance_id"], :name => "idx_tree_node_instance_id"
    t.index ["literal"], :name => "idx_tree_node_literal"
    t.index ["name_id", "tree_arrangement_id"], :name => "idx_tree_node_name_id_in"
    t.index ["name_id"], :name => "idx_tree_node_name_id"
    t.index ["name_uri_id_part", "name_uri_ns_part_id", "tree_arrangement_id"], :name => "idx_tree_node_name_in"
    t.index ["name_uri_id_part", "name_uri_ns_part_id"], :name => "idx_tree_node_name"
    t.index ["next_node_id"], :name => "tree_node_next"
    t.index ["prev_node_id"], :name => "tree_node_prev"
    t.index ["resource_uri_id_part", "resource_uri_ns_part_id", "tree_arrangement_id"], :name => "idx_tree_node_resource_in"
    t.index ["resource_uri_id_part", "resource_uri_ns_part_id"], :name => "idx_tree_node_resource"
    t.index ["taxon_uri_id_part", "taxon_uri_ns_part_id", "tree_arrangement_id"], :name => "idx_tree_node_taxon_in"
    t.index ["taxon_uri_id_part", "taxon_uri_ns_part_id"], :name => "idx_tree_node_taxon"
    t.foreign_key ["checked_in_at_id"], "tree_event", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_nlq0qddnhgx65iojhj2xm8tay"
    t.foreign_key ["instance_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_1g9477sa8plad5cxkxmiuh5b"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_eqw4xo7vty6e4tq8hy34c51om"
    t.foreign_key ["name_uri_ns_part_id"], "tree_uri_ns", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_gc6f9ykh7eaflvty9tr6n4cb6"
    t.foreign_key ["replaced_at_id"], "tree_event", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_pc0tkp9bgp1cxull530y60v46"
    t.foreign_key ["resource_uri_ns_part_id"], "tree_uri_ns", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_4y1qy9beekbv71e9i6hto6hun"
    t.foreign_key ["taxon_uri_ns_part_id"], "tree_uri_ns", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_16c4wgya68bwotwn6f50dhw69"
    t.foreign_key ["type_uri_ns_part_id"], "tree_uri_ns", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_oge4ibjd3ff3oyshexl6set2u"
  end

  add_foreign_key "tree_node", ["next_node_id"], "tree_node", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_sbuntfo4jfai44yjh9o09vu6s"
  add_foreign_key "tree_node", ["prev_node_id"], "tree_node", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_budb70h51jhcxe7qbtpea0hi2"

  create_table "tree_arrangement", force: true do |t|
    t.integer "lock_version", limit: 8,   default: 0, null: false
    t.string  "tree_type",    limit: nil,             null: false
    t.string  "description"
    t.string  "label",        limit: 50
    t.integer "node_id",      limit: 8
    t.string  "is_synthetic", limit: nil,             null: false
    t.string  "title",        limit: 50
    t.index ["label"], :name => "tree_arrangement_label"
    t.index ["label"], :name => "uk_y303qbh1ijdg3sncl9vlxus0", :unique => true
    t.index ["node_id"], :name => "tree_arrangement_node"
    t.foreign_key ["node_id"], "tree_node", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_fvfq13j3dqv994o9vg54yj5kk"
  end

  add_foreign_key "tree_node", ["tree_arrangement_id"], "tree_arrangement", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_t6kkvm8ubsiw6fqg473j0gjga"

  create_table "name_tree_path", force: true do |t|
    t.integer "version",   limit: 8,    null: false
    t.integer "inserted",  limit: 8,    null: false
    t.integer "name_id",   limit: 8,    null: false
    t.integer "next_id",   limit: 8
    t.integer "parent_id", limit: 8
    t.string  "path",      limit: 4000, null: false
    t.integer "tree_id",   limit: 8,    null: false
    t.string  "tree_path", limit: 4000, null: false
    t.index ["name_id"], :name => "name_tree_path_name_index"
    t.index ["path"], :name => "name_tree_path_path_index"
    t.index ["tree_path"], :name => "name_tree_path_treepath_index"
    t.foreign_key ["name_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_j4j0kq9duod9gm019pl1xec7c"
    t.foreign_key ["next_id"], "name_tree_path", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_try5dwb6jcy5fngk09bf7f7on"
    t.foreign_key ["parent_id"], "name_tree_path", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_sfj3hoevcuni3ak7no6byjp3"
    t.foreign_key ["tree_id"], "tree_arrangement", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_3xnmxe5p6ed258euacrfflwrj"
  end

  create_table "nomenclatural_event_type", force: true do |t|
    t.integer "lock_version",             limit: 8,  default: 0, null: false
    t.integer "name_group_id",            limit: 8,              null: false
    t.string  "nomenclatural_event_type", limit: 50
    t.text    "description_html"
    t.string  "rdf_id",                   limit: 50
    t.index ["rdf_id"], :name => "nomenclatural_event_type_rdfid"
    t.foreign_key ["name_group_id"], "name_group", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_ql5g85814a9y57c1ifd0nkq3v"
  end

  create_table "notification", force: true do |t|
    t.integer "version",   limit: 8, null: false
    t.string  "message",             null: false
    t.integer "object_id", limit: 8
  end

  create_table "nsl_simple_name", force: true do |t|
    t.string   "apc_comment",           limit: 4000
    t.string   "apc_distribution",      limit: 4000
    t.boolean  "apc_excluded",                       default: false, null: false
    t.string   "apc_familia"
    t.integer  "apc_instance_id",       limit: 8
    t.string   "apc_name",              limit: 512
    t.boolean  "apc_proparte",                       default: false, null: false
    t.string   "apc_relationship_type"
    t.boolean  "apni",                               default: false
    t.string   "author"
    t.string   "authority"
    t.boolean  "autonym",                            default: false
    t.string   "base_name_author"
    t.string   "classifications"
    t.string   "classis"
    t.datetime "created_at"
    t.string   "created_by"
    t.boolean  "cultivar",                           default: false, null: false
    t.string   "cultivar_name"
    t.integer  "dup_of_id",             limit: 8
    t.string   "ex_author"
    t.string   "ex_base_name_author"
    t.string   "familia"
    t.integer  "family_nsl_id",         limit: 8
    t.boolean  "formula",                            default: false, null: false
    t.string   "full_name_html",        limit: 2048
    t.string   "genus"
    t.integer  "genus_nsl_id",          limit: 8
    t.boolean  "homonym",                            default: false
    t.boolean  "hybrid",                             default: false
    t.string   "infraspecies"
    t.string   "name",                                               null: false
    t.string   "name_element"
    t.integer  "name_rank_id",          limit: 8,                    null: false
    t.integer  "name_status_id",        limit: 8,                    null: false
    t.integer  "name_type_id",          limit: 8,                    null: false
    t.string   "name_type_name",                                     null: false
    t.boolean  "nom_illeg",                          default: false
    t.boolean  "nom_inval",                          default: false
    t.string   "nom_stat",                                           null: false
    t.integer  "parent_nsl_id",         limit: 8
    t.integer  "proto_year",            limit: 2
    t.string   "rank",                                               null: false
    t.string   "rank_abbrev"
    t.integer  "rank_sort_order"
    t.string   "sanctioning_author"
    t.boolean  "scientific",                         default: false
    t.integer  "second_parent_nsl_id",  limit: 8
    t.string   "simple_name_html",      limit: 2048
    t.string   "species"
    t.integer  "species_nsl_id",        limit: 8
    t.string   "subclassis"
    t.string   "taxon_name",            limit: 512,                  null: false
    t.datetime "updated_at"
    t.string   "updated_by"
    t.string   "basionym",              limit: 512
    t.string   "proto_citation",        limit: 512
    t.integer  "proto_instance_id",     limit: 8
    t.string   "replaced_synonym",      limit: 512
    t.foreign_key ["apc_instance_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_lgtnu32ysbg6l2ys5d6bhfgmq"
    t.foreign_key ["family_nsl_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_on28vygd1e7aqn9owbhv3u23h"
    t.foreign_key ["genus_nsl_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_ctg301hhg3x41rjl09d7noti1"
    t.foreign_key ["name_rank_id"], "name_rank", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_k4ryd8xarm9hhk1aitqtfg0tb"
    t.foreign_key ["name_status_id"], "name_status", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_bexlla3pvlm2x8err16puv16f"
    t.foreign_key ["name_type_id"], "name_type", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_gbcxpwubk8cdlh5fxnd3ln4up"
    t.foreign_key ["parent_nsl_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_kquvd2hkcl7aj2vhylvp1k7vb"
    t.foreign_key ["proto_instance_id"], "instance", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_59i6is32bt6v19i51ql9n2r9i"
    t.foreign_key ["second_parent_nsl_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_mvjeehgt584v9ep11ixe1iyok"
    t.foreign_key ["species_nsl_id"], "name", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_rpqdbhi21sdix5tmmj5ul61su"
  end

  create_table "nsl_simple_name_export", id: false, force: true do |t|
    t.text     "id"
    t.string   "apc_comment",           limit: 4000
    t.string   "apc_distribution",      limit: 4000
    t.boolean  "apc_excluded"
    t.string   "apc_familia"
    t.text     "apc_instance_id"
    t.string   "apc_name",              limit: 512
    t.boolean  "apc_proparte"
    t.string   "apc_relationship_type"
    t.boolean  "apni"
    t.string   "author"
    t.string   "authority"
    t.boolean  "autonym"
    t.string   "basionym",              limit: 512
    t.string   "base_name_author"
    t.string   "classifications"
    t.datetime "created_at"
    t.string   "created_by"
    t.boolean  "cultivar"
    t.string   "cultivar_name"
    t.string   "ex_author"
    t.string   "ex_base_name_author"
    t.string   "familia"
    t.text     "family_nsl_id"
    t.boolean  "formula"
    t.string   "full_name_html",        limit: 2048
    t.string   "genus"
    t.text     "genus_nsl_id"
    t.boolean  "homonym"
    t.boolean  "hybrid"
    t.string   "infraspecies"
    t.string   "name"
    t.string   "classis"
    t.string   "name_element"
    t.string   "subclassis"
    t.string   "name_type_name"
    t.boolean  "nom_illeg"
    t.boolean  "nom_inval"
    t.string   "nom_stat"
    t.text     "parent_nsl_id"
    t.string   "proto_citation",        limit: 512
    t.text     "proto_instance_id"
    t.integer  "proto_year",            limit: 2
    t.string   "rank"
    t.string   "rank_abbrev"
    t.integer  "rank_sort_order"
    t.string   "replaced_synonym",      limit: 512
    t.string   "sanctioning_author"
    t.boolean  "scientific"
    t.text     "second_parent_nsl_id"
    t.string   "simple_name_html",      limit: 2048
    t.string   "species"
    t.text     "species_nsl_id"
    t.string   "taxon_name",            limit: 512
    t.datetime "updated_at"
    t.string   "updated_by"
  end

  create_table "trashing_event", force: true do |t|
    t.integer  "lock_version", limit: 8,    default: 0, null: false
    t.datetime "created_at",                            null: false
    t.string   "created_by",   limit: 4000,             null: false
    t.datetime "updated_at",                            null: false
    t.string   "updated_by",   limit: 4000,             null: false
  end

  create_table "trashed_item", force: true do |t|
    t.integer  "lock_version",      limit: 8,                             default: 0, null: false
    t.datetime "created_at",                                                          null: false
    t.string   "created_by",        limit: 4000,                                      null: false
    t.decimal  "trashable_id",                   precision: 19, scale: 2,             null: false
    t.string   "trashable_type",    limit: 4000,                                      null: false
    t.integer  "trashing_event_id", limit: 8
    t.datetime "updated_at",                                                          null: false
    t.string   "updated_by",        limit: 4000,                                      null: false
    t.foreign_key ["trashing_event_id"], "trashing_event", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_bd6arfjuj28nolsc58i345ybg"
  end

  create_table "tree_link", force: true do |t|
    t.integer "lock_version",        limit: 8,   default: 0, null: false
    t.integer "link_seq",                                    null: false
    t.integer "subnode_id",          limit: 8,               null: false
    t.integer "supernode_id",        limit: 8,               null: false
    t.string  "is_synthetic",        limit: nil,             null: false
    t.string  "type_uri_id_part"
    t.integer "type_uri_ns_part_id", limit: 8,               null: false
    t.string  "versioning_method",   limit: nil,             null: false
    t.index ["subnode_id"], :name => "tree_link_subnode"
    t.index ["supernode_id", "link_seq"], :name => "idx_tree_link_seq", :unique => true
    t.index ["supernode_id"], :name => "tree_link_supernode"
    t.foreign_key ["subnode_id"], "tree_node", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_tgankaahxgr4p0mw4opafah05"
    t.foreign_key ["supernode_id"], "tree_node", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_kqshktm171nwvk38ot4d12w6b"
    t.foreign_key ["type_uri_ns_part_id"], "tree_uri_ns", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_2dk33tolvn16lfmp25nk2584y"
  end

  create_table "user_query", force: true do |t|
    t.integer  "lock_version",       limit: 8,                             default: 0,     null: false
    t.datetime "created_at",                                                               null: false
    t.boolean  "query_completed",                                          default: false, null: false
    t.boolean  "query_started",                                            default: false, null: false
    t.decimal  "record_count",                    precision: 19, scale: 2,                 null: false
    t.datetime "search_finished_at"
    t.string   "search_info",        limit: 500
    t.string   "search_model",       limit: 4000
    t.text     "search_result"
    t.datetime "search_started_at"
    t.string   "search_terms",       limit: 4000
    t.boolean  "trash",                                                    default: false, null: false
    t.datetime "updated_at",                                                               null: false
  end

end
