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

# Instances connect Names to References.
class Instance < ActiveRecord::Base
  extend AdvancedSearch
  extend SearchTools
  include ActionView::Helpers::TextHelper
  strip_attributes

  self.table_name = "instance"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  scope :ordered_by_name, -> { joins(:name).order("simple_name asc") }
  scope :ordered_by_page, lambda {
    order("Lpad(
            Regexp_replace(
              Regexp_replace(page, '[A-z. ]','','g'),
            '[^0-9]*([0-9][0-9]*).*', '\\1')
            ||
            Regexp_replace(
                Regexp_replace(page, '.*-.*', '~'),
            '[^~].*','0'),
          12,'0'),
          page,
          name.full_name")
  }

  scope :in_nested_instance_type_order, lambda {
    order(
      "          case instance_type.name " \
      "          when 'basionym' then 1 " \
      "          when 'replaced synonym' then 2 " \
      "          when 'common name' then 99 " \
      "          when 'vernacular name' then 99 " \
      "          else 3 end, " \
      "          case nomenclatural " \
      "          when true then 1 " \
      "          else 2 end, " \
      "          case taxonomic " \
      "          when true then 2 " \
      "          else 1 end ")
  }

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
  scope :changed_in_the_last_n_days, ->(n) { where("current_date - created_at::date < ?  or current_date - updated_at::date < ?", n, n) }

  scope :for_ref, ->(ref_id) { where(reference_id: ref_id) }
  scope :for_ref_and_correlated_on_name_id, lambda \
    { |ref_id|
      where(["exists (select null from instance i2
             where i2.reference_id = ? and instance.name_id = i2.name_id)",
             ref_id])
    }
  # scope :order_by_name_full_name, -> { joins(:name).order(name: [:full_name])}
  scope :order_by_name_full_name, -> { joins(:name).order(" name.full_name ") }

  attr_accessor :expanded_instance_type, :display_as, :relationship_flag,
                :give_me_focus, :legal_to_order_by,
                :show_primary_instance_type, :data_fix_in_process,
                :consider_apc
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  belongs_to :reference
  belongs_to :name
  belongs_to :instance_type

  belongs_to :this_cites, class_name: "Instance", foreign_key: "cites_id"
  has_many :reverse_of_this_cites,
           class_name: "Instance",
           inverse_of: :this_cites,
           foreign_key: "cites_id"
  has_many :citeds, class_name:
           "Instance",
                    inverse_of: :this_cites,
                    foreign_key: "cites_id"

  belongs_to :this_is_cited_by,
             class_name: "Instance",
             foreign_key: "cited_by_id"

  has_many :reverse_of_this_is_cited_by,
           class_name: "Instance",
           inverse_of: :this_is_cited_by,
           foreign_key: "cited_by_id"

  has_many :citations,
           class_name: "Instance",
           inverse_of: :this_is_cited_by,
           foreign_key: "cited_by_id"

  has_many :instance_notes,
           dependent: :restrict_with_error

  # has_many :apc_instance_notes,
  #         class_name: "InstanceNote",
  #         dependent: :restrict_with_error,
  #         -> { "where instance_note_key_id in
  #         (select id from instance_note_key
  #         where ink.name in ('APC Comment', 'APC Dist.')" }

  has_many :comments

  validates_presence_of :name_id,
                        :reference_id,
                        :instance_type_id,
                        message: "cannot be empty."

  validates :name_id,
            uniqueness:
              { scope: [:reference_id,
                        :instance_type_id,
                        :cites_id,
                        :cited_by_id,
                        :page],
                message: "already has instance with same ref, type and page" }

  validate :relationship_ref_must_match_cited_by_instance_ref,
           :synonymy_name_must_match_cites_instance_name,
           :cites_id_with_no_cited_by_id_is_invalid,
           :cannot_cite_itself,
           :cannot_be_cited_by_itself
  validate :synonymy_must_keep_cites_id, on: :update
  validate :name_id_must_not_change, on: :update
  validate :standalone_reference_id_can_change_if_no_dependents, on: :update

  SEARCH_LIMIT = 50
  DEFAULT_DESCRIPTOR = "n" # for name
  DEFAULT_ORDER_BY = "verbatim_name_string asc "
  LEGAL_TO_ORDER_BY = { "n" => "verbatim_name_string" }

  before_validation :set_defaults
  before_create :set_defaults
  # before_update :update_allowed?

  def apc_instance_notes
    instance_notes.apc
  end

  def non_apc_instance_notes
    instance_notes.non_apc
  end

  def name_id_must_not_change
    errors[:base] << "You cannot use a different name." if name_id_changed?
  end

  # A standalone instance with no dependents can change reference.
  def standalone_reference_id_can_change_if_no_dependents
    if reference_id_changed? &&
       standalone? &&
       reverse_of_this_is_cited_by.present?
      errors[:base] << "this instance has relationships, "
      errors[:base] << "so you cannot alter the reference."
    end
  end

  # Update of name_id is not allowed.
  # Update of reference_id is allowed only for standlone instances
  # and only if they have no is_cited_by [relationship]
  # instance children.
  def update_allowed?
    !name_id_changed? &&
      (!reference_id_changed? ||
      (standalone? && reverse_of_this_is_cited_by.blank?))
  end

  def update_reference_allowed?
    standalone? && reverse_of_this_is_cited_by.blank?
  end

  def relationship_ref_must_match_cited_by_instance_ref
    if self.relationship? && !(reference.id == this_is_cited_by.reference.id)
      errors.add(:reference_id,
                 "must match cited by instance reference")
    end
  end

  def to_s
    "#{id}; \n#{type_of_instance} instance; \nname: #{name.try('full_name')}:
    \nref: #{reference.try('citation')}; \ncited_by: #{cited_by_id}
    \ncited by ref: #{this_is_cited_by.try('reference').try('citation')}
    \ncites name: #{this_cites.try('name').try('full_name')}"
  rescue => e
    "Error in to_s: #{e}"
  end

  def synonymy_name_must_match_cites_instance_name
    return if !self.synonymy? || name.id == this_cites.name.id
    errors.add(:name_id, "must match cites instance name")
  end

  def cites_id_with_no_cited_by_id_is_invalid
    return unless cites_id.present? && cited_by_id.blank?
    errors[:base] << "A cites id with no cited by id is invalid."
  end

  def cannot_cite_itself
    return if !self.synonymy? || id != cites_id
    errors[:base] << "cannot cite itself"
  end

  def cannot_be_cited_by_itself
    return if !self.relationship? || id != cited_by_id
    errors.add(:name_id, "cannot be cited by itself")
  end

  def synonymy_must_keep_cites_id
    return if cites_id.present?
    return if Instance.find(id).cites_id.nil? || data_fix_in_process
    errors.add(:cites_id, "cannot be removed once saved")
  end

  def default_descriptor
    DEFAULT_DESCRIPTOR
  end

  def default_order_by
    DEFAULT_ORDER_BY
  end

  def legal_to_order_by
    LEGAL_TO_ORDER_BY
  end

  def relationship_flag
    true if cites_id || cited_by_id
  end

  # The four plus one types of instance -
  # based on null/not null state of the two fields:
  # - cited_by_id
  # - cites_id
  def standalone?
    cited_by_id.nil? && cites_id.nil?
  end

  def synonymy?
    relationship? && cites_id.present?
  end

  def unpublished_citation?
    relationship? && cites_id.nil?
  end

  def unrecognised?
    cited_by_id.nil? && cites_id.present?
  end

  def type_of_instance
    case
    when standalone? then "Standalone"
    when synonymy? then "Synonymy"
    when unpublished_citation? then "Unpublished citation"
    else
      "Unknown - unrecognised type"
    end
  end

  def is_cited_by
    Instance.where(cited_by_id: id).collect do |instance|
      instance.display_as = "cited-by-instance"
      instance
    end
  end

  def cites_this
    unless cited_by_id.nil?
      instance = Instance.find_by_id(cited_by_id)
      instance.expanded_instance_type = instance_type.name + " of"
      instance.display_as = "cites-this-instance"
      instance
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update!(attributes)
  end

  def fresh?
    created_at > 1.hour.ago
    # || (created_at == updated_at && created_at > 1.day.ago)
  end

  def allow_delete?
    instance_notes.blank? &&
      reverse_of_this_cites.blank? &&
      reverse_of_this_is_cited_by.blank? && comments.blank?
  end

  def anchor_id
    "Instance-#{id}"
  end

  def show_apc?
    name.apc? && id == name.apc_instance_id
  end

  def apc_excluded?
    apc_instance_is_an_excluded_name == true
  end

  def set_defaults
    # self.instance_type_id = InstanceType.unknown.id if instance_type.blank?
    self.namespace_id = Namespace.apni.id if namespace_id.blank?
  end

  # simple i.e. not a relationship instance
  def simple?
    cites_id.blank? && cited_by_id.blank?
  end

  # simple i.e. not a relationship instance
  def relationship?
    !simple?
  end

  def type
    simple? ? "simple" : "relationship"
  end

  def misapplied?
    instance_type.misapplied?
  end

  def self.find_references
    ->(title) { Reference.where(" lower(title) = ?", title.downcase) }
  end

  def self.find_names
    ->(simple_name) { Name.where(" lower(simple_name) = ?", simple_name.downcase) }
  end

  def self.expansion(search_string)
    expand_wanted = !search_string.match(/expand:/).nil?
    logger.debug("display should be:  expand_wanted: #{expand_wanted}")
    [expand_wanted, search_string.gsub(/expand:[^ ]*/, "")]
  end

  def self.extract_query_token(search_string, requested_token)
    token = search_string.match(/#{requested_token}:[^ ]*/)
    token.to_s
  end

  def self.consume_token(search_string, requested_token)
    found_token = search_string.match(/#{requested_token.downcase}:[^ ]*/)
    [!found_token.blank?,
     search_string.gsub(/#{requested_token.downcase}:/, "")]
  end

  def self.get_id_for(search_string, query_token)
    pair = extract_query_token(search_string, query_token)
    id = pair.gsub(/#{query_token}:/, "")
    id
  end

  def self.instance_context(instance_id)
    logger.debug("#{'=' * 66} instance_context")
    results = []
    rejected_pairings = []

    instance = find(instance_id)
    instance.name.display_as_part_of_concept
    results.push(instance.name)
    instance.display_as = "instance-for-expansion"
    results.push(instance)
    instance.is_cited_by.each do |cited_by|
      cited_by.expanded_instance_type = cited_by.instance_type.name
      results.push(cited_by)
    end
    results.push(instance.cites_this) unless instance.cites_this.nil?
    results
  end

  def self.ref_instances(search_string, limit = 100)
    logger.debug(%(ref_instances search for "#{search_string}"
                 with limit: #{limit}))
    results = []
    Reference.where([" lower(citation) like ? ",
                     "%" + search_string.downcase + "%"])
      .order("citation").limit(limit).each do |ref|
      results.concat(Instance.ref_usages(ref.id))
    end
    results
  end

  def self.ref_usages(search_string, limit = 100, order_by = "name",
                      show_instances = true)
    logger.debug("Start new ref_usages: search string: #{search_string};
                 show_instances: #{show_instances};
                 limit: #{limit}; order by: #{order_by}")
    reference_id = search_string.to_i
    extra_search_terms = search_string.to_s.sub(/[0-9][0-9]*/, "")
    results = []
    rejected_pairings = []
    # But what if that reference no longer exists?
    reference = Reference.find_by(id: reference_id)
    unless reference.blank?
      reference.display_as_part_of_concept
      count = 1
      query = reference
              .instances
              .joins(:name)
              .includes(name: :name_status)
              .includes(:instance_type)
              .includes(this_is_cited_by: [:name, :instance_type])
      query = order_by == "page" ? query.ordered_by_page : query.ordered_by_name
      query.each do |instance|
        logger.debug("Query loop.....")
        if count < limit
          if instance.cited_by_id.blank?
            count += 1
            if show_instances
              instance.display_within_reference
              results.push(instance)
              instance.is_cited_by.each do |cited_by|
                count += 1
                cited_by.expanded_instance_type = cited_by.instance_type.name
                results.push(cited_by)
                if count > limit
                  limited = true
                  break
                end
              end
              unless instance.cites_this.nil?
                results.push(instance.cites_this)
                count += 1
                if count > limit
                  limited = true
                  break
                end
              end
            end
          end
        end
        if count > limit
          limited = true
          break
        end
      end
      results.unshift(reference)
    end
    results
  end

  # Instances of a name algorithm starts here.
  def self.name_instances(name_search_string, limit = 100, apply_limit = true)
    logger.debug(%(-- Name.name_instances search for "#{name_search_string}"
                 with limit: #{limit}))
    results = []
    names,
        rejected_pairings,
        limited,
        focus_anchor_id,
        info = Name::AsSearchEngine.search(name_search_string,
                                           limit, false, true, apply_limit)
    names.each do |name|
      if name.instances.size > 0
        results.concat(Instance::AsSearchEngine.name_usages(name.id))
      end
    end
    results
  end

  # Instances targetted in nsl-720
  def self.nsl_720
    logger.debug("nsl_720")
    results = Instance
              .where("id in (?) ",
                     [3_593_450, 3_455_690, 3_455_747, 3_587_295, 3_534_663,
                      3_454_920, 3_454_936, 3_536_329, 3_456_370, 3_454_931,
                      3_454_850, 3_454_945, 3_498_251, 3_454_966, 3_456_380,
                      3_480_899, 3_524_687, 3_456_385, 3_458_910, 3_454_921,
                      3_454_961, 3_526_347, 3_456_333, 3_506_487, 3_455_711,
                      3_508_136, 3_454_956, 3_455_757, 3_454_975, 3_456_353,
                      3_454_976, 3_545_422, 3_489_094, 3_456_371, 3_456_350,
                      3_509_786, 3_463_066, 3_547_132, 3_511_437, 3_516_396,
                      3_503_189, 3_479_256, 3_480_890, 3_548_842, 3_504_839,
                      3_454_926, 3_513_089, 3_455_691, 3_514_742, 3_480_894,
                      3_480_902, 3_484_174, 3_454_950, 3_552_262, 3_484_176,
                      3_454_910, 3_454_896, 3_518_051, 3_484_178, 3_455_692,
                      3_585_418, 3_454_869, 3_559_102, 3_455_752, 3_485_815,
                      3_456_351, 3_454_901, 3_482_538, 3_454_895, 3_487_453,
                      3_503_192, 3_553_972, 3_455_732, 3_555_682, 3_456_373,
                      3_454_951, 3_529_670, 3_455_742, 3_563_245, 3_490_734,
                      3_562_028, 3_455_699, 3_519_710, 3_454_911, 3_455_766,
                      3_492_375, 3_492_378, 3_454_870, 3_518_054, 3_455_729,
                      3_586_356, 3_455_767, 3_455_702, 3_499_895, 3_455_712,
                      3_550_552, 3_501_540, 3_519_713, 3_454_867, 3_460_541,
                      3_531_333, 3_501_543, 3_588_277, 3_454_830, 3_455_730,
                      3_560_812, 3_456_352, 3_456_372, 3_480_893, 3_557_392,
                      3_521_370, 3_456_328, 3_523_028, 3_454_868, 3_528_008,
                      3_454_885, 3_455_731, 3_460_547, 3_455_741, 3_455_689,
                      3_454_886])
  end

  def self.reverse_of_cites_id_query(instance_id)
    instance = Instance.find_by(id: instance_id.to_i)
    results = instance.present? ? instance.reverse_of_this_cites : []
  end

  def self.reverse_of_cited_by_id_query(instance_id)
    instance = Instance.find_by(id: instance_id.to_i)
    results = instance.present? ? instance.reverse_of_this_is_cited_by : []
  end

  def self.show_simple_instance_within_all_synonyms(starting_point_name,
                                                    instance)
    results = []
    instance.name.display_as_part_of_concept
    results.push(instance.name)
    instance.display_as_part_of_concept
    results.push(instance)
    Instance.where(cited_by_id: instance.id).each do |cited_by_orig_instance|
      next unless cited_by_orig_instance.name == starting_point_name
      cited_by_orig_instance.expanded_instance_type =
        cited_by_orig_instance.instance_type.name_as_a_noun
      cited_by_orig_instance.display_as = "cited-by-instance"
      results.push(cited_by_orig_instance)
    end
    results
  end

  def self.name_synonymy(name_id)
    results = []
    rejected_pairings = []
    already_shown = []
    name = Name.find(name_id)
    name.display_as_part_of_concept
    name.instances.sort do |i1, i2|
      [i1.reference.year, i1.reference.author.name] <=>
        [i2.reference.year, i2.reference.author.name]
    end.each do |instance|
      if instance.simple?
        Instance.show_simple_instance_within_all_unfiltered_synonyms(name,
                                                                     instance)
          .each { |element| results.push(element) }
      else # relationship instance
        unless already_shown.include?(instance.id)
          Instance.show_simple_instance_within_all_unfiltered_synonyms(name,
                                                                       instance
            .this_is_cited_by).each { |element| results.push(element) }
          already_shown.push(instance.this_is_cited_by.id)
        end
      end
    end
    results
  end

  def self.show_simple_instance_within_all_unfiltered_synonyms(
    _starting_point_name,
    instance)
    results = []
    instance.name.display_as_part_of_concept
    results.push(instance.name)
    instance.display_as_part_of_concept
    results.push(instance)
    Instance.where(cited_by_id: instance.id).each do |cited_by_orig_instance|
      cited_by_orig_instance.expanded_instance_type =
        cited_by_orig_instance.instance_type.name_as_a_noun
      cited_by_orig_instance.display_as =
        "cited-by-instance-within-full-synonymy"
      results.push(cited_by_orig_instance)
    end
    logger.debug(results.size)
    results
  end

  def display_as_part_of_concept
    self.display_as = :instance_as_part_of_concept
    self
  end

  def display_within_reference
    self.display_as = :instance_within_reference
    self
  end

  def display_as_citing_instance_within_name_search
    self.display_as = :citing_instance_within_name_search
    self
  end

  # This turns field descriptors into parts of a where clause.
  # It is for "specific" field descriptors.
  # The "generic" field descriptors should have been consumed beforehand.
  def self.bindings_to_where(search_terms_array, where, binds)
    logger.debug("Instance#bindings_to_where: search terms
                 array: #{search_terms_array.join(',')}; where: #{where};
                 binds: {binds}")
    rejected_pairings = []
    search_terms_array.each do |pairing|
      logger.debug "pairing: #{pairing}"
      logger.debug "pairing class: #{pairing.class}"
      logger.debug "pairing size: #{pairing.size}"
      if pairing.class == String
        case pairing.downcase
        when "with-comments"
          where += " and exists (select null from comment
                   where comment.reference_id = reference.id) "
        end
      elsif pairing.size == 2
        case pairing[0].downcase
        when "id"
          where += " and id = ? "
          binds.push(prepare_search_term_string(pairing[1]))
        when "instance-type"
          where += " and instance_type_id =
          (select id from instance_type where instance_type.name = ?) "
          binds.push(pairing[1])
        when /^verbatim-name-string$/
          where += " and lower(verbatim_name_string) like ? "
          binds.push(prepare_search_term_string(pairing[1]))
        when "name-id"
          where += " and name_id = ? "
          binds.push(pairing[1])
        when "reference-id"
          where += " and reference_id = ? "
          binds.push(pairing[1])
        when "ref"
          where += " and reference_id = ? "
          binds.push(pairing[1])
        when "instance-note-key"
          where += " and exists (select null from instance_note
                   where instance_note.instance_id = instance.id
                   and exists (select null from instance_note_key
                   where instance_note.instance_note_key_id in
                   (select id from instance_note_key
                   where lower(name) like '%'||lower(?)||'%'))) "
          binds.push(pairing[1])
        when /\Anote\z/
          where += " and exists (select null from instance_note
                   where instance_note.instance_id = instance.id
                   and lower(instance_note.value) like ?)"
          binds.push(prepare_search_term_string(pairing[1]))
        when "with-comments"
          where += " and exists (select null from comment
                   where comment.instance_id = instance.id
                   and comment.text like ?) "
          binds.push(prepare_search_term_string(pairing[1]))
        when "with-comments-by"
          where += " and exists (select null from comment
                   where comment.instance_id = instance.id
                   and (lower(comment.created_by) like ?
                   or lower(comment.updated_by) like ?)) "
          binds.push(prepare_search_term_string(pairing[1]))
          binds.push(prepare_search_term_string(pairing[1]))
        else
          rejected_pairings.push(pairing.join(":"))
          logger.error "Rejected pairing: #{pairing}"
        end
      else
        # don't treat it as an array even
        # to avoid errors with criteria like: "x:"
        logger.debug("pairing size: #{pairing}")
        rejected_pairings.push(pairing)
        logger.error "Rejected pairing: #{pairing}"
      end
    end
    where.sub!(/\A *and/, "")
    [where, binds, rejected_pairings]
  end

  # Return the set of stand-alone instances associated with a name.
  # Used in synonymy typeahead.
  def self.for_a_name(query)
    Instance.joins(reference: :author)
      .joins(:name)
      .joins(:instance_type)
      .select("instance.id, reference.year, reference.citation,
               reference.pages, reference.source_system,
               instance_type.name instance_type_name, name.full_name ")
      .where(["cited_by_id is null and cites_id is null
               and lower(name.full_name) like lower(?)",
              "%#{query}%"])
      .order("reference.year, author.name").limit(20)
      .collect do |i|
      # # value = "#{i.full_name} in #{i.citation}:#{i.year} #{'[' + i.pages
      # + ']' unless i.pages.blank? || i.pages.match(/null - null/)}"
      value = "#{i.full_name} in #{i.citation}:#{i.year} "
      unless i.pages.blank? || i.pages.match(/null - null/)
        value = "[#{i.pages}] "
      end
      value += "[#{i.instance_type_name}]" unless i.instance_type_name ==
                                                  "secondary reference"
      value += "[#{i.source_system.downcase}]" unless i.source_system.blank?
      id = i.id
      { value: value, id: id }
    end
  end

  # For NSL-720
  def self.synonyms_that_should_be_unpublished_citations
    long_sql = <<-EOT
      SELECT     i.id,
                 i.cites_id,
                 i.created_by,
                 To_char(i.created_at,'dd-Mon-yyyy') created,
                 i.updated_by,
                 To_char(i.updated_at,'dd-Mon-yyyy') updated,
                 t.NAME,
                 n.full_name,
                 r.id "reference",
                 cites_ref.id "cites_ref",
                 r.citation
      FROM       instance i
      INNER JOIN instance_type t
      ON         i.instance_type_id = t.id
      INNER JOIN NAME n
      ON         i.name_id = n.id
      INNER JOIN reference r
      ON         i.reference_id = r.id
      INNER JOIN instance cites
      ON         i.cites_id = cites.id
      INNER JOIN reference cites_ref
      ON         cites.reference_id = cites_ref.id
      WHERE      i.created_at > Now() - interval '40 days'
      AND        t.NAME = 'common name'
      AND        r.id = cites_ref.id
      ORDER BY   i.id
      EOT
    Instance.find_by_sql(long_sql)
  end

  # Call with argument :commit to commit; any other argument will rollback.
  def change_synonymy_to_unpublished_citation(commit_or_not = :or_not)
    puts "Start change_synonymy_to_unpublished_citation for instance #{id}"
    fail "Expected synonymy but this is not synonymy!" unless synonymy?
    redundant_instance = Instance.find(cites_id)
    same_reference = this_is_cited_by.reference.id == reference.id
    fail "Expected same reference but that is not true!" unless same_reference
    puts "id: #{id}; cited_by_id: #{cited_by_id}; cites: #{cites_id};
    to be removed: #{redundant_instance.id}; same reference: #{same_reference} "
    puts "synonymy?: #{synonymy?}"
    puts "type of instance: #{type_of_instance}"
    Instance.transaction do
      # bypass a validation that would prevent this change
      self.data_fix_in_process = true
      # remove the foreign key then delete the record
      self.cites_id = nil
      self.save!
      redundant_instance.destroy!
      if unpublished_citation?
        puts "As expected, the record is now an unpublished citation instance."
      else
        puts "Unexpected result: record has not become an unpublished citation!"
        puts "Rolling back."
        fail ActiveRecord::Rollback
      end
      if commit_or_not == :commit
        puts("Committing...(commit_or_not: #{commit_or_not})")
      else
        puts("Not committing...(commit_or_not: #{commit_or_not})")
        fail(ActiveRecord::Rollback)
      end
    end
    self
  end

  # Call with argument :commit to commit; any other argument will rollback.
  def self.nsl_720_data_change(commit_or_not = :or_not, how_many = 1)
    done = 0
    Instance.synonyms_that_should_be_unpublished_citations.each do |rec|
      relationship = Instance.find(rec.id)
      relationship.change_synonymy_to_unpublished_citation(commit_or_not)
      done += 1
      break if done == how_many
    end
    done
  end

  # Notes:
  # - sets the updated_by column to audit the user who is deleting the record.
  # - avoid validation on that update - otherwise the delete will not occur.
  def delete_as_user(username)
    update_attribute(:updated_by, username)
    Instance::AsServices.delete(id)
  rescue => e
    logger.error("delete_as_user exception: #{e}")
    raise
  end

  # Assemble the attributes and related entities into a standard CSV
  # view of an instance.
  def for_csv
    attributes
      .values_at("id", "name_id")
      .concat(name.attributes.values_at("full_name"))
      .concat(attributes.values_at("reference_id"))
      .concat(reference.attributes.values_at("citation"))
      .concat(instance_notes
      .sort do |x, y|
        x.instance_note_key.sort_order <=> y.instance_note_key.sort_order
      end
      .each
      .collect { |n| [n.instance_note_key.name, n.value] })
      .flatten
  end
end
