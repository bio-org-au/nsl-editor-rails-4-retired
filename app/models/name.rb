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
require "advanced_search"
require "search_tools"

class Name < ActiveRecord::Base
  extend AdvancedSearch
  extend SearchTools

  strip_attributes
  # acts_as_tree

  self.table_name = "name"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  attr_accessor :display_as,
                :give_me_focus,
                :apc_instance_id,
                :apc_instance_is_an_excluded_name,
                :apc_declared_bt,
                :change_category_to

  scope :not_common_or_cultivar,
        -> { where([" name_type_id in (select id from name_type where not (cultivar or lower(name_type.name) = 'common'))"]) }
  scope :not_a_duplicate, -> { where(duplicate_of_id: nil) }
  scope :with_an_instance, -> { where(["exists (select null from instance where name.id = instance.name_id)"]) }
  scope :full_name_like, ->(string) { where("lower(f_unaccent(full_name)) like f_unaccent(?) ", string.gsub(/\*/, "%").downcase + "%") }
  scope :lower_full_name_equals, ->(string) { where("lower(f_unaccent(full_name)) = f_unaccent(?) ", string.downcase) }
  scope :lower_full_name_like, ->(string) { where("lower(f_unaccent(full_name)) like f_unaccent(?) ", string.gsub(/\*/, "%").downcase) }
  scope :lower_rank_like, ->(string) { where("name_rank_id in (select id from name_rank where lower(name) like ?)", string.gsub(/\*/, "%").downcase) }
  scope :order_by_full_name, -> { order("lower(full_name)") }
  scope :select_fields_for_typeahead, -> { select(" name.id, name.full_name, name_rank.name name_rank_name, name_status.name name_status_name") }
  scope :select_fields_for_parent_typeahead, -> { select(" name.id, name.full_name, name_rank.name name_rank_name, name_status.name name_status_name, count(instance.id) instance_count") }
  scope :from_a_higher_rank, ->(rank_id) { joins(:name_rank).where("name_rank.sort_order < (select sort_order from name_rank where id = ?)", rank_id) } # tested
  scope :ranks_for_unranked, -> { joins(:name_rank).where("name_rank.sort_order <= (select sort_order from name_rank where name = 'Subforma') or name_rank.name = '[unranked]' ") }
  scope :ranks_for_unranked_assumes_join, -> { where("name_rank.sort_order <= (select sort_order from name_rank where name = 'Subforma') or name_rank.name = '[unranked]' ") }
  scope :but_rank_not_too_high, lambda { |rank_id|
    where("name_rank.id in (select id from name_rank where sort_order >= " \
                   "(select max(sort_order) from name_rank where major and name not in ('Tribus','Ordo','Classis','Division') " \
                   " and sort_order <  (select sort_order from name_rank where id = ?)))", rank_id)
  }
  scope :name_rank_not_deprecated, -> { where("not name_rank.deprecated") }
  scope :name_rank_not_infra,
         -> { where("name_rank.name not in ('[infrafamily]','[infragenus]','[infrasp.]') ") }
  scope :name_rank_not_na, -> { where("name_rank.name != '[n/a]' ") }
  scope :name_rank_not_unknown, -> { where("name_rank.name != '[unknown]' ") }
  scope :name_rank_not_unranked, -> { where("name_rank.name != '[unranked]' ") }
  scope :name_rank_species_and_below, -> { where("name_rank.sort_order >= (select sort_order from name_rank sp where sp.name = 'Species')") }
  scope :name_rank_genus_and_below, -> { where("name_rank.sort_order >= (select sort_order from name_rank genus where genus.name = 'Genus')") }
  scope :avoids_id, ->(avoid_id) { where("name.id != ?", avoid_id) }
  scope :all_children, ->(parent_id) { where("name.parent_id = ? or name.second_parent_id = ?", parent_id, parent_id) }
  scope :for_id, ->(id) { where("name.id = ?", id) }

  scope :created_n_days_ago,
        ->(n) { where("current_date - created_at::date = ?", n) }
  scope :updated_n_days_ago,
        ->(n) { where("current_date - updated_at::date = ?", n) }
  scope :changed_n_days_ago,
        ->(n) { where("current_date - created_at::date = ? or current_date - updated_at::date = ?", n, n) }

  scope :created_in_the_last_n_days,
        ->(n) { where("current_date - created_at::date < ?", n) }
  scope :updated_in_the_last_n_days,
        ->(n) { where("current_date - updated_at::date < ?", n) }
  scope :changed_in_the_last_n_days,
        ->(n) { where("current_date - created_at::date < ? or current_date - updated_at::date < ?", n, n) }

  belongs_to :name_rank
  belongs_to :name_type
  belongs_to :name_status
  belongs_to :author
  belongs_to :ex_author, class_name: "Author"
  belongs_to :base_author, class_name: "Author"
  belongs_to :ex_base_author, class_name: "Author"
  belongs_to :sanctioning_author, class_name: "Author"
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"

  belongs_to :duplicate_of, class_name: "Name", foreign_key: "duplicate_of_id"
  has_many :duplicates,
           class_name: "Name",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_exception # , order: 'name_element'

  has_many :instances,
           foreign_key: "name_id",
           dependent: :restrict_with_error
  # has_many   :instances_for_name_usages, -> { includes :instance_type},
  # class: Instance, foreign_key: 'name_id', dependent: :restrict_with_error

  belongs_to :parent, class_name: "Name", foreign_key: "parent_id"
  has_many :children,
           class_name: "Name",
           foreign_key: "parent_id",
           dependent: :restrict_with_exception
  belongs_to :second_parent, class_name: "Name", foreign_key: "second_parent_id"
  has_many :second_children,
           class_name: "Name",
           foreign_key: "second_parent_id",
           dependent: :restrict_with_exception
  has_many :just_second_children, -> { where "parent_id != second_parent_id" },
           class_name: "Name", foreign_key: "second_parent_id",
           dependent: :restrict_with_exception
  has_many :comments
  has_many :name_tag_names
  has_many :name_tags, through: :name_tag_names
  has_one :apc_tree_path,
          -> { where "exists (select null from tree_arrangement ta where tree_id = ta.id and ta.description = 'Australian Plant Census')" },
          class_name: "NameTreePath"
  has_one :apni_tree_path,
          -> { where "exists (select null from tree_arrangement ta where tree_id = ta.id and ta.description = 'APNI names classification')" },
          class_name: "NameTreePath"

  validates :name_rank_id, presence: true
  validates :name_type_id, presence: true
  validates :name_status_id, presence: true
  validates :ex_base_author,
            absence: { message: "cannot be set if there is no base author.",
                       if: "base_author_id.nil?" }
  validates :base_author,
            absence: { message: "cannot be set if there is no author.",
                       if: "author_id.nil?" }
  validates :ex_author,
            absence: { message: "cannot be set if there is no author.",
                       if: "author_id.nil?" }
  validates :name_element, presence: true, if: :requires_name_element?
  validate :name_element_is_stripped
  validates :parent_id, presence: true, if: :requires_parent? # tested
  validate :parent_rank_high_enough? # tested
  validate :name_type_must_match_category
  validate :author_and_ex_author_must_differ
  validate :base_author_and_ex_base_author_must_differ
  validates :created_by, presence: true
  validates :updated_by, presence: true

  validates_length_of :status_summary, maximum: 50
  validates_exclusion_of :duplicate_of_id,
                         in: ->(name) { [name.id] },
                         allow_blank: true,
                         message: "and master cannot be the same record"
  validates_exclusion_of :parent_id,
                         in: ->(name) { [name.id] },
                         allow_blank: true,
                         message: "cannot be the same record"
  validates_exclusion_of :second_parent_id,
                         in: ->(name) { [name.id] },
                         allow_blank: true,
                         message: "cannot be the same record"
  validates_exclusion_of :second_parent_id,
                         in: ->(name) { [name.parent_id] },
                         allow_blank: true,
                         message: "cannot be the same as the first parent",
                         unless: "cultivar_hybrid?"

  validates :second_parent_id, presence: true, if: :requires_parent_2?
  validates :second_parent_id, absence: true, unless: :requires_parent_2?
  validates :verbatim_rank, length: { maximum: 50 }

  SEARCH_LIMIT = 50
  AUTOCOMPLETE_SEARCH_LIMIT = 20
  DEFAULT_DESCRIPTOR = "n" # for full_name
  DEFAULT_ORDER_BY = "full_name"
  LEGAL_TO_ORDER_BY = { "fn" => "full_name",
                        "sn" => "simple_name",
                        "ne" => "name_element",
                        "r" => "name_rank_id" }

  # Category constants
  SCIENTIFIC_CATEGORY = "scientific"
  SCIENTIFIC_HYBRID_FORMULA_CATEGORY = "scientific hybrid formula"
  SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY =
    "scientific hybrid formula unknown 2nd parent"
  CULTIVAR_CATEGORY = "cultivar"
  CULTIVAR_HYBRID_CATEGORY = "cultivar hybrid"
  OTHER_CATEGORY = "other"

  DECLARED_BT = "DeclaredBt"

  before_create :set_defaults
  before_save :validate

  def descendents
    Name.all_children(id)
  end

  def combined_children
    Name.all_children(id)
  end

  def name_type_must_match_category
    return if NameType.option_ids_for_category(category).include?(name_type_id)
    errors.add(:name_type_id,
               "Wrong name type for category! Category: #{category} vs
               name type: #{name_type.name}.")
  end

  def author_and_ex_author_must_differ
    if author_id.present? && ex_author_id.present? && author_id == ex_author_id
      errors[:base] << "The ex-author cannot be the same as the author."
    end
  end

  def base_author_and_ex_base_author_must_differ
    return unless base_author_id.present? &&
                  ex_base_author_id.present? &&
                  base_author_id == ex_base_author_id
    errors[:base] << "The ex-base author cannot be the same as the base author."
  end

  def parent_rank_above?
    parent.present? &&
      parent.name_rank.present? &&
      name_rank.present? &&
      parent.name_rank.above?(name_rank)
  end

  def name_element_is_stripped
    return unless name_element.present?
    return if name_element == name_element.strip
    errors.add(:name_element, "has whitespace")
  end

  def both_unranked?
    name_rank_id == parent.name_rank_id && name_rank.unranked?
  end

  def parent_rank_high_enough?
    if requires_parent? && requires_higher_ranked_parent?
      unless parent.blank? || parent_rank_above? || both_unranked?
        errors.add(:parent_id, "rank (#{parent.try('name_rank').try('name')})
                   must be higher than the name rank (#{name_rank.try('name')})"
                  )
      end
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username(attributes, username)
    self.updated_by = username
    update_attributes(attributes)
  end

  def validate
    logger.debug("before save validate - errors: #{errors[:base].size}")
    errors[:base].size == 0
  end

  def self.exclude_common_and_cultivar_if_requested(exclude)
    if exclude
      not_common_or_cultivar
    else
      where("1=1")
    end
  end

  def category
    change_category_to.present? ? change_category_to : raw_category
  end

  def raw_category
    case name_type.try("name") || nil
    when "autonym"
      then SCIENTIFIC_CATEGORY
    when "hybrid formula unknown 2nd parent"
      then SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
    when "named hybrid"
      then SCIENTIFIC_CATEGORY
    when "named hybrid autonym"
      then SCIENTIFIC_CATEGORY
    when "sanctioned"
      then SCIENTIFIC_CATEGORY
    when "scientific"
      then SCIENTIFIC_CATEGORY
    when "phrase name"
      then SCIENTIFIC_CATEGORY
    when "cultivar hybrid formula"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "graft/chimera"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "hybrid"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "hybrid autonym"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "hybrid formula parents known"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "intergrade"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "formula"
      then SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "acra"
      then CULTIVAR_CATEGORY
    # deprecated name type
    when "acra hybrid"
      then CULTIVAR_HYBRID_CATEGORY
    when "cultivar"
      then CULTIVAR_CATEGORY
    when "cultivar hybrid"
      then CULTIVAR_HYBRID_CATEGORY
    when "pbr"
      then CULTIVAR_CATEGORY
    # deprecated name type
    when "pbr hybrid"
      then CULTIVAR_HYBRID_CATEGORY
    when "trade"
      then CULTIVAR_CATEGORY
    # deprecated name type
    when "trade hybrid"
      then CULTIVAR_HYBRID_CATEGORY
    when "[default]"
      then OTHER_CATEGORY
    when "[n/a]"
      then OTHER_CATEGORY
    when "[unknown]"
      then OTHER_CATEGORY
    when "common"
      then OTHER_CATEGORY
    when "informal"
      then OTHER_CATEGORY
    else OTHER_CATEGORY
    end
  end

  def status_options
    NameStatus.options_for_category(category, allow_delete?)
  end

  def takes_name_element?
    !(category == SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY)
  end

  def takes_status?
    category == SCIENTIFIC_CATEGORY
  end

  def takes_rank?
    category == SCIENTIFIC_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == CULTIVAR_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY
  end

  def takes_parent_1?
    category == SCIENTIFIC_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == CULTIVAR_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
  end

  def requires_parent?
    category != OTHER_CATEGORY && name_rank.present? && name_rank.has_parent?
  end

  def requires_parent_1?
    category != OTHER_CATEGORY
  end

  def takes_parent_2?
    category == SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY
  end

  def requires_parent_2?
    category == SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY
  end

  def takes_hybrid_scoped_parent?
    category == SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
  end

  def takes_cultivar_scoped_parent?
    category == CULTIVAR_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY
  end

  def parent_rule
    case category
    when SCIENTIFIC_HYBRID_FORMULA_CATEGORY
      then "hybrid - species and below or unranked if unranked"
    when SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
      then "hybrid - species and below or unranked if unranked"
    when CULTIVAR_HYBRID_CATEGORY
      then "cultivar - genus and below, or unranked if unranked"
    when CULTIVAR_CATEGORY
      then "cultivar - genus and below, or unranked if unranked"
    else
      "ordinary - restricted by rank, or unranked if unranked"
    end
  end

  def second_parent_rule
    case category
    when SCIENTIFIC_HYBRID_FORMULA_CATEGORY
      then "hybrid - species and below or unranked if unranked"
    when CULTIVAR_HYBRID_CATEGORY
      then "cultivar - genus and below, or unranked if unranked"
    else ""
    end
  end

  def takes_authors?
    category == SCIENTIFIC_CATEGORY
  end

  def requires_name_element?
    category == SCIENTIFIC_CATEGORY ||
      category == CULTIVAR_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY ||
      category == OTHER_CATEGORY
  end

  def needs_top_buttons?
    category == SCIENTIFIC_CATEGORY
  end

  def requires_higher_ranked_parent?
    category == SCIENTIFIC_CATEGORY
  end

  def has_only_one_type?
    category == CULTIVAR_CATEGORY ||
      category == CULTIVAR_HYBRID_CATEGORY ||
      category == SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
  end

  def self.created_in_the_last(amount = 1, time_unit = "hour")
    Name.where("created_at > now() - interval '#{amount}  #{time_unit}'")
  end

  def rank_takes_parent?
    parent_name_rank.real_parent?
  end

  def parent_name_rank
    name_rank.parent
  end

  def full_name_or_default
    full_name || "[this record has no full name]"
  end

  def display_as_part_of_concept
    self.display_as = :name_as_part_of_concept
  end

  def allow_delete?
    instances.blank? && children.blank? && comments.blank?
  end

  def migrated_from_apni?
    !source_system.blank?
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def anchor_id
    "Name-#{id}"
  end

  def apc_excluded?
    apc_instance_is_an_excluded_name == true
  end

  def apc_declared_bt?
    apc_declared_bt == true
  end

  def get_apc_json
    Rails.cache.fetch("#{cache_key}/apc_info", expires_in: 2.minutes) do
      JSON.load(open(Name::AsServices.in_apc_url(id)))
    end
  rescue => e
    logger.error("Name#get_apc_json exception: #{e} for URL: #{Name::AsServices.in_apc_url(id)}")
    "[unknown - service error]"
  end

  def apc?
    logger.debug("apc?")
    json = get_apc_json
    if json["inAPC"] == true
      self.apc_instance_id = json["taxonId"].to_i
      self.apc_declared_bt = (json["type"] == DECLARED_BT)
      self.apc_instance_is_an_excluded_name =
        (!apc_declared_bt && json["excluded"] == true)
    else
      self.apc_instance_id = nil
      self.apc_instance_is_an_excluded_name = false
      self.apc_declared_bt = false
    end
    return !apc_instance_id.nil?
  rescue => e
    logger.error("Name::apc? exception: #{e}")
    self.apc_instance_id = nil
    false
  end

  def get_in_apni
    logger.info("get_in_apni; service call unless cached...")
    Rails.cache.fetch("#{cache_key}/in_apni", expires_in: 1.minutes) do
      JSON.load(open(Name::AsServices.in_apni_url(id), read_timeout: 1))
    end
  rescue => e
    logger.error("Name#get_in_apni error: #{e}")
    raise
  end

  def apni?
    json = get_in_apni
    json["inAPNI"] == true
  rescue => e
    logger.error("Is this in APNI name error.")
    logger.error(e.to_s)
    false
  end

  def get_apni_family
    logger.info("get_apni_family; service call unless cached...")
    Rails.cache.fetch("#{cache_key}/apni_info", expires_in: 1.minutes) do
      JSON.load(open(Name::AsServices.apni_family_url(id), read_timeout: 1))
    end
  rescue => e
    logger.error("Name#get_apni_family exception: #{e} for URL:
                 #{Name::AsServices.apni_family_url(id)}")
    raise
  end

  def apni_family_name
    json = get_apni_family
    json["familyName"]["name"]["simpleName"]
  rescue => e
    logger.error("apni_family_name error: #{e}")
    "apni family unknown - service error: #{e}"
  end

  def has_parent?
    parent_id.present?
  end

  def has_second_parent?
    second_parent.present?
  end

  def without_parent?
    !self.has_parent?
  end

  def needs_second_parent?
    self.hybrid? && !self.has_second_parent?
  end

  def hybrid?
    name_type.hybrid?
  end

  def self.count_search_results(raw)
    logger.debug("Just counting names")
    just_count_them = true
    count = search(raw, just_count_them)
    logger.debug(count)
    count
  end

  def self.id_search?(search_string)
    search_string.match(/ id: *[\d]+/) ||
      search_string.match(/\Aid: *[\d]+/)
  end

  def self.dummy_record
    find_by_name_element("Unknown")
  end

  def self.find_authors
    ->(abbrev) { Author.where(" lower(abbrev) = ?", abbrev.downcase) }
  end

  def self.find_names
    ->(full_name) { Name.where(" lower(full_name) = ?", full_name.downcase) }
  end

  def self.find_genera
    ->(name_element) { Name.where(" name_rank_id = (select id from name_rank where lower(name) = 'genus') and lower(name_element) = ? ", name_element.downcase) }
  end

  def get_names_json
    logger.debug("get_names_json start for id: #{id}")
    logger.debug("Name::AsServices.name_strings_url(id) for
                 id: #{id}: #{Name::AsServices.name_strings_url(id)}")
    JSON.load(open(Name::AsServices.name_strings_url(id)))
  end

  # Use update_columns to avoid validation errors, stale object
  # errors and timestamp changes.
  def refresh_constructed_name_fields
    names_json = get_names_json
    if full_name != names_json["result"]["fullName"] ||
       full_name_html != names_json["result"]["fullMarkedUpName"] ||
       simple_name != names_json["result"]["simpleName"] ||
       simple_name_html != names_json["result"]["simpleMarkedUpName"]

      update_columns(full_name: names_json["result"]["fullName"],
                     full_name_html: names_json["result"]["fullMarkedUpName"],
                     simple_name: names_json["result"]["simpleName"],
                     simple_name_html:
                     names_json["result"]["simpleMarkedUpName"])
      1
    else
      0
    end
  rescue => e
    logger.error("refresh_constructed_name_field! exception: #{e}")
    raise
  end

  def set_names!
    logger.debug("set_names!")
    names_json = get_names_json
    self.full_name = names_json["result"]["fullName"]
    self.full_name_html = names_json["result"]["fullMarkedUpName"]
    self.simple_name = names_json["result"]["simpleName"]
    self.simple_name_html = names_json["result"]["simpleMarkedUpName"]
    self.save!
    logger.debug("end of set_names!")
  rescue => e
    logger.error("set_names! exception: #{e}")
    raise
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def cultivar_hybrid?
    category == CULTIVAR_HYBRID_CATEGORY
  end

  def sub_tree_size(level = 0)
    if level == 0
      puts "level 0"
      @size_ = 0
    end
    @size_ ||= 0
    @size_ += 1
    level += 1
    children.each do |child|
      @size_ += child.sub_tree_size(level)
    end
    puts "level: #{level}; @size: #{@size_}"
    @size_
  end

  def refresh_tree
    @tally ||= 0
    @tally += refresh_constructed_name_fields
    children.each do |child|
      @tally += child.refresh_tree
    end
    just_second_children.each do |child|
      @tally += child.refresh_tree
    end
    @tally
  end

  private

  def set_defaults
    self.namespace_id = Namespace.apni.id if namespace_id.blank?
  end
end
