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
require 'advanced_search'
require 'search_tools'

class Instance < ActiveRecord::Base
  extend AdvancedSearch
  extend SearchTools
  include ActionView::Helpers::TextHelper
  strip_attributes

  self.table_name = 'instance'
  self.primary_key = 'id'
  self.sequence_name = 'nsl_global_seq'

  scope :ordered_by_name, -> {joins(:name).order('simple_name asc')}
  # Explanation for each step below - working from the innermost function out i.e. down
  # emulate numeric page ordering.
  # remove dash and anything following; case: 19-20; sort as 19
  # remove alphas, etc
  # ltrim spaces
  # ltrim comma
  # remove comma and anything after it
  # left pad with plenty of zeros to emulate numeric sort on strings
  # then sort on page (again, but the whole field) to correctly order cases like '75, t. 101', '75, t. 102'
  # noting this does not solve cases like '74, t. 100', '74, t. 99'
  scope :ordered_by_page, -> {order("lpad(
                                       regexp_replace(
                                         regexp_replace(
                                           regexp_replace(
                                             regexp_replace(
                                               regexp_replace(page,'-.*$',''),  
                                             '[A-z. ]','','g'),                 
                                           '^  *',''),                          
                                         '^,',''),                              
                                       ',.*',''),                               
                                     12,'0'),name.full_name")}
 
  scope :in_nested_instance_type_order, -> {order(
                         "          case instance_type.name " +
                         "          when 'basionym' then 1 " +
                         "          when 'replaced synonym' then 2 " +
                         "          when 'common name' then 99 " +
                         "          when 'vernacular name' then 99 " +
                         "          else 3 end, " +
                         "          case nomenclatural " +
                         "          when true then 1 " +
                         "          else 2 end, " +
                         "          case taxonomic " +
                         "          when true then 2 " +
                         "          else 1 end ")}

  attr_accessor :expanded_instance_type, :display_as, :relationship_flag, 
                :give_me_focus, :legal_to_order_by, 
                :show_primary_instance_type, :show_apc_tick, :data_fix_in_process,
                :consider_for_apc_tick
  belongs_to :namespace, class_name: 'Namespace', foreign_key: 'namespace_id'
  belongs_to :reference
  belongs_to :name
  belongs_to :instance_type

  belongs_to :this_cites, class_name: 'Instance', foreign_key: 'cites_id'
  has_many :reverse_of_this_cites, class_name: 'Instance', inverse_of: :this_cites, foreign_key: 'cites_id'
  has_many :citeds               , class_name: 'Instance', inverse_of: :this_cites, foreign_key: 'cites_id'

  belongs_to :this_is_cited_by, class_name: 'Instance', foreign_key: 'cited_by_id'
  has_many :reverse_of_this_is_cited_by, class_name: 'Instance', inverse_of: :this_is_cited_by, foreign_key: 'cited_by_id'
  has_many :citations,                   class_name: 'Instance', inverse_of: :this_is_cited_by, foreign_key: 'cited_by_id'

  has_many :instance_notes, dependent: :restrict_with_error
  has_many :comments

  validates_presence_of :name_id, :reference_id, :instance_type_id, message: 'cannot be empty.'
  validates :name_id, uniqueness: { scope: [:reference_id, :instance_type_id, :cites_id, :cited_by_id, :page], 
                                    message: 'already has an instance with the same reference, type and page' }

  validate :relationship_ref_must_match_cited_by_instance_ref,
           :synonymy_name_must_match_cites_instance_name,
           :cites_id_with_no_cited_by_id_is_invalid,
           :cannot_cite_itself,
           :cannot_be_cited_by_itself
  validate :synonymy_must_keep_cites_id, on: :update
  validate :name_id_must_not_change, on: :update
  validate :standalone_reference_id_can_change_if_no_dependents, on: :update

  SEARCH_LIMIT = 50
  DEFAULT_DESCRIPTOR = 'n' # for name
  DEFAULT_ORDER_BY = 'verbatim_name_string asc '
  LEGAL_TO_ORDER_BY = {'n' => 'verbatim_name_string'}

  before_validation :set_defaults
  before_create :set_defaults
  #before_update :update_allowed?

  def name_id_must_not_change
    errors[:base] << 'You cannot use a different name.' if name_id_changed?
  end

  # A standalone instance with no dependents can change reference.
  def standalone_reference_id_can_change_if_no_dependents
    errors[:base] << 'this instance has relationships, so you cannot alter the reference.' if reference_id_changed? && standalone? && reverse_of_this_is_cited_by.present?
  end

  # Update of name_id is not allowed.
  # Update of reference_id is allowed only for standlone instances
  # and only if they have no is_cited_by [relationship]
  # instance children.
  def update_allowed?
    !name_id_changed? &&
             (!reference_id_changed? || (standalone? && reverse_of_this_is_cited_by.blank?))
  end

  def update_reference_allowed?
    standalone? && reverse_of_this_is_cited_by.blank?
  end

  def relationship_ref_must_match_cited_by_instance_ref
    errors.add(:reference_id, 'must match cited by instance reference') if self.relationship? && !(self.reference.id == self.this_is_cited_by.reference.id)
  end

  def to_s
    "#{id}; \n#{type_of_instance} instance; \nname: #{name.try('full_name')}: \nref: #{reference.try('citation')}; \ncited_by: #{cited_by_id}" +
    "\ncited by ref: #{this_is_cited_by.try('reference').try('citation')}" +
    "\ncites name: #{this_cites.try('name').try('full_name')}"
  rescue => e
    'error in to_s'
  end

  def synonymy_name_must_match_cites_instance_name
    errors.add(:name_id, 'must match cites instance name') unless !self.synonymy? || self.name.id == self.this_cites.name.id
  end

  def cites_id_with_no_cited_by_id_is_invalid
    errors[:base] << 'A cites id with no cited by id is invalid.' if cites_id.present? && cited_by_id.blank?
  end

  def cannot_cite_itself
    errors[:base] << 'cannot cite itself' unless !self.synonymy? || self.id != self.cites_id
  end

  def cannot_be_cited_by_itself
    errors.add(:name_id, 'cannot be cited by itself') unless !self.relationship? || self.id != self.cited_by_id
  end

  def synonymy_must_keep_cites_id
    errors.add(:cites_id, 'cannot be removed once saved') unless self.cites_id.present? || Instance.find(self.id).cites_id.nil? || self.data_fix_in_process
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
    true if self.cites_id || self.cited_by_id
  end

  # The four plus one types of instance - based on null/not null state of the two fields:
  # - cited_by_id
  # - cites_id
  def standalone?
    cited_by_id.nil? && cites_id.nil?
  end

  def relationship?
    cited_by_id.present?
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
    when standalone? then 'Standalone'
    when synonymy? then 'Synonymy'
    when unpublished_citation? then 'Unpublished citation'
    else
      'Unknown - unrecognised type'
    end
  end
  
  def is_cited_by
    Instance.where({cited_by_id:self.id}).collect do |instance|
      instance.display_as = 'cited-by-instance'
      instance
    end
  end

  def cites_this
    unless self.cited_by_id.nil?
      instance = Instance.find_by_id(self.cited_by_id)
      instance.expanded_instance_type = self.instance_type.name + ' of'
      instance.display_as = 'cites-this-instance'
      instance
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes,username)
    self.updated_by = username
    update!(attributes)
  end

  # Watch out for empty fields.
  def would_change?(params)
    Rails.logger.debug('Instance#would_change')
    change = false
    params.each do |name,value| 
      Rails.logger.debug("Instance#would_change: field name: #{name}; param field value: #{value}; current field value: #{self[name].to_s}")
      change = change || !(self[name] && value == self[name].to_s)
      Rails.logger.debug("change: #{change}")
    end
    change
  rescue => e
    logger.error("Instance#would_change? exception.")
    logger.error(e.to_s)
    false
  end

  def fresh?
    created_at > 1.hour.ago #|| (created_at == updated_at && created_at > 1.day.ago)
  end

  def allow_delete?
    instance_notes.blank? && reverse_of_this_cites.blank? && reverse_of_this_is_cited_by.blank? && comments.blank?
  end

  def anchor_id
    "Instance-#{self.id}"
  end

  def apc_yn
  #  Name.find_by_sql(["select apc_tree.is_apc_instance(?) apc_instance from dual", self.id]).first.apc_instance
  #rescue => e
    'U'
  end
 
  def show_apc_tick?
    name.apc? && id == name.apc_instance_id
  end

  def apc_accepted?
    apc_yn == 'Y'
  end

  def apc_excluded?
    apc_instance_is_an_excluded_name == true
  end

  def set_defaults
    #self.instance_type_id = InstanceType.unknown.id if instance_type.blank?
    self.namespace_id = Namespace.apni.id if self.namespace_id.blank?
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
    simple? ? 'simple' : 'relationship'
  end
  
  def misapplied?
    instance_type.misapplied?
  end

  def self.find_references
    lambda {|title| Reference.where(' lower(title) = ?',title.downcase)}
  end
  
  def self.find_names
    lambda {|simple_name| Name.where(' lower(simple_name) = ?',simple_name.downcase)}
  end
   
  def self.expansion(search_string)
    expand_wanted = !search_string.match(/expand:/).nil?
    logger.debug("display should be:  expand_wanted: #{expand_wanted}")
    return expand_wanted,search_string.gsub(/expand:[^ ]*/,'')
  end

  def self.extract_query_token(search_string,requested_token)
    token = search_string.match(/#{requested_token}:[^ ]*/)
    return token.to_s
  end

  def self.consume_token(search_string,requested_token)
    found_token = search_string.match(/#{requested_token.downcase}:[^ ]*/)
    return !found_token.blank?,search_string.gsub(/#{requested_token.downcase}:/,'')
  end

  def self.get_id_for(search_string,query_token)
    pair = self.extract_query_token(search_string,query_token)
    id = pair.gsub(/#{query_token}:/,'')
    id
  end

  def self.instance_context(instance_id)
    logger.debug("#{'='*66} instance_context")
    results = []
    rejected_pairings = []

    instance = self.find(instance_id)
    instance.name.display_as_part_of_concept
    results.push(instance.name)
    instance.display_as = 'instance-for-expansion'
    results.push(instance)
    instance.is_cited_by.each do |cited_by| 
      cited_by.expanded_instance_type = cited_by.instance_type.name
      results.push(cited_by)
    end
    results.push(instance.cites_this) unless instance.cites_this.nil?
    results
  end

  def self.ref_instances(search_string,limit = 100)
    logger.debug(%Q(ref_instances search for "#{search_string}" with limit: #{limit}))
    results = []
    Reference.where([' lower(citation) like ? ','%'+search_string.downcase+'%']).order('citation').limit(limit).each do |ref|
      results.concat(Instance.ref_usages(ref.id))
    end
    results
  end

  def self.ref_usages(search_string, limit = 100, order_by = 'name', show_instances = true)
    logger.debug("Start new ref_usages: search string: #{search_string}; show_instances: #{show_instances}; limit: #{limit}; order by: #{order_by}")
    reference_id = search_string.to_i
    extra_search_terms = search_string.to_s.sub(/[0-9][0-9]*/,'')
    results = []
    rejected_pairings = []
    # But what if that reference no longer exists?
    reference = Reference.find_by(id: reference_id)
    unless reference.blank?
      reference.display_as_part_of_concept
      count = 0 
      query = reference.instances.joins(:name).includes({name: :name_status}).includes(:instance_type).includes(this_is_cited_by: [:name, :instance_type])
      query = order_by == 'page' ? query.ordered_by_page : query.ordered_by_name
      query.each do |instance|
        if count < limit
          if instance.cited_by_id.blank?
            count += 1
            if show_instances
              instance.display_within_reference
              results.push(instance)
              instance.is_cited_by.each do |cited_by| 
                cited_by.expanded_instance_type = cited_by.instance_type.name
                results.push(cited_by)
              end 
              results.push(instance.cites_this) unless instance.cites_this.nil?
            end
          end
        end  
      end
      results.unshift(reference)
    end
    results
  end

  # Instances of a name algorithm starts here.
  def self.name_instances(name_search_string,limit = 100,apply_limit = true)
    logger.debug(%Q(-- Name.name_instances search for "#{name_search_string}" with limit: #{limit}))
    names = []
    results = []
    names,
        rejected_pairings,
        limited,
        focus_anchor_id,
        info = Name::AsSearchEngine.search(name_search_string,limit,false,true,apply_limit)
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
    results = Instance.where("id in (?) ",[3593450,3455690,3455747,3587295,3534663,3454920,3454936,3536329,3456370,3454931,
      3454850,3454945,3498251,3454966,3456380,3480899,3524687,3456385,3458910,3454921,
      3454961,3526347,3456333,3506487,3455711,3508136,3454956,3455757,3454975,3456353,
      3454976,3545422,3489094,3456371,3456350,3509786,3463066,3547132,3511437,3516396,
      3503189,3479256,3480890,3548842,3504839,3454926,3513089,3455691,3514742,3480894,
      3480902,3484174,3454950,3552262,3484176,3454910,3454896,3518051,3484178,3455692,
      3585418,3454869,3559102,3455752,3485815,3456351,3454901,3482538,3454895,3487453,
      3503192,3553972,3455732,3555682,3456373,3454951,3529670,3455742,3563245,3490734,
      3562028,3455699,3519710,3454911,3455766,3492375,3492378,3454870,3518054,3455729,
      3586356,3455767,3455702,3499895,3455712,3550552,3501540,3519713,3454867,3460541,
      3531333,3501543,3588277,3454830,3455730,3560812,3456352,3456372,3480893,3557392,
      3521370,3456328,3523028,3454868,3528008,3454885,3455731,3460547,3455741,3455689,3454886])
  end

  def self.reverse_of_cites_id_query(instance_id)
    instance = Instance.find_by(id: instance_id.to_i)
    results = instance.present? ? instance.reverse_of_this_cites : []
  end

  def self.reverse_of_cited_by_id_query(instance_id)
    instance = Instance.find_by(id: instance_id.to_i)
    results = instance.present? ? instance.reverse_of_this_is_cited_by : []
  end

  def self.show_simple_instance_within_all_synonyms(starting_point_name,instance)
    results = []
    instance.name.display_as_part_of_concept
    results.push(instance.name)
    instance.display_as_part_of_concept
    results.push(instance)
    Instance.where({cited_by_id:instance.id}).each do |cited_by_original_instance|
      if cited_by_original_instance.name == starting_point_name
        cited_by_original_instance.expanded_instance_type = cited_by_original_instance.instance_type.name_as_a_noun
        cited_by_original_instance.display_as = 'cited-by-instance'
        results.push(cited_by_original_instance)
      end       
    end
    results
  end

  def self.name_synonymy(name_id)
    results = []
    rejected_pairings = []
    already_shown = []
    name = Name.find(name_id)
    name.display_as_part_of_concept
    name.instances.sort {|i1,i2| [i1.reference.year,i1.reference.author.name] <=> [i2.reference.year,i2.reference.author.name] }.each do |instance|
      if instance.simple?
        Instance.show_simple_instance_within_all_unfiltered_synonyms(name,instance).each {|element| results.push(element)}
      else # relationship instance
        unless already_shown.include?(instance.id)
          Instance.show_simple_instance_within_all_unfiltered_synonyms(name,instance.this_is_cited_by).each {|element| results.push(element)}
          already_shown.push(instance.this_is_cited_by.id)
        end
      end
    end
    results
  end

  def self.show_simple_instance_within_all_unfiltered_synonyms(starting_point_name,instance)
    results = []
    instance.name.display_as_part_of_concept
    results.push(instance.name)
    instance.display_as_part_of_concept
    results.push(instance)
    Instance.where({cited_by_id:instance.id}).each do |cited_by_original_instance|
        cited_by_original_instance.expanded_instance_type = cited_by_original_instance.instance_type.name_as_a_noun
        cited_by_original_instance.display_as = 'cited-by-instance-within-full-synonymy'
        results.push(cited_by_original_instance)
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
  # It is for "specific" field descriptors.  The "generic" field descriptors should have been consumed beforehand.
  def self.bindings_to_where(search_terms_array,where,binds)
    logger.debug("Instance#bindings_to_where: search terms array: #{search_terms_array.join(',')}; where: #{where}; binds: {binds}")
    logger.debug("--------------------------------------------------------------------------------------")
    rejected_pairings = []
    search_terms_array.each do | pairing |
      logger.debug "pairing: #{pairing}"
      logger.debug "pairing class: #{pairing.class}"
      logger.debug "pairing size: #{pairing.size}"
      if pairing.class == String         
        case pairing.downcase
        when 'with-comments'
          where += " and exists (select null from comment where comment.reference_id = reference.id) "
        end
      elsif pairing.size == 2         
        case pairing[0].downcase
        when 'id'
          where += " and id = ? "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'instance-type'
          where += " and instance_type_id =  (select id from instance_type where instance_type.name = ?) "
          binds.push(pairing[1])
        when /^verbatim-name-string$/ 
          where += " and lower(verbatim_name_string) like ? "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'name-id'
          where += " and name_id = ? "
          binds.push(pairing[1])
        when 'reference-id'
          where += " and reference_id = ? "
          binds.push(pairing[1])
        when 'ref'
          where += " and reference_id = ? "
          binds.push(pairing[1])
        when 'instance-note-key'
          where += " and exists (select null from instance_note where instance_note.instance_id = instance.id and exists (select null from instance_note_key where instance_note.instance_note_key_id in (select id from instance_note_key where lower(name) like '%'||lower(?)||'%'))) "
          binds.push(pairing[1])
        when 'with-comments'
          where += " and exists (select null from comment where comment.instance_id = instance.id and comment.text like ?) "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'with-comments-by'
          where += " and exists (select null from comment where comment.instance_id = instance.id and (lower(comment.created_by) like ? or lower(comment.updated_by) like ?)) "
          binds.push(prepare_search_term_string(pairing[1]))
          binds.push(prepare_search_term_string(pairing[1]))
        else
          rejected_pairings.push(pairing.join(':'))
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
    where.sub!(/\A *and/,'')
    return where,binds,rejected_pairings
  end

  # Return the set of stand-alone instances associated with a name.
  # Used in synonymy typeahead.
  def self.for_a_name(query)
    Instance.joins(reference: :author).
             joins(:name).
             joins(:instance_type).
             select('instance.id, reference.year, reference.citation, ' +
                    "reference.pages, reference.source_system, instance_type.name instance_type_name, name.full_name ").
             where(["cited_by_id is null and cites_id is null and lower(name.full_name) like lower(?)","%#{query}%"]).
             order('reference.year, author.name').limit(20).
             collect do | i | 
               value = "#{i.full_name} in #{i.citation}:#{i.year} #{'['+i.pages+']' unless i.pages.blank? || i.pages.match(/null - null/)}"
               value += "[#{i.instance_type_name}]"  unless i.instance_type_name == 'secondary reference'
               value += "[#{i.source_system.downcase}]" unless i.source_system.blank?
               id = i.id
               {value: value, id: id}
             end
  end

  # For NSL-720
  def self.synonyms_that_should_be_unpublished_citations
    long_sql=<<-EOT 
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
    raise "Expected synonymy but this is not synonymy!" unless synonymy?
    redundant_instance = Instance.find(cites_id)
    same_reference = this_is_cited_by.reference.id == reference.id
    raise "Expected same reference but that is not true!" unless same_reference
    puts "id: #{id}; cited_by_id: #{cited_by_id}; cites: #{cites_id}; to be removed: #{redundant_instance.id}; same reference: #{same_reference} "
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
        raise ActiveRecord::Rollback
      end
      if commit_or_not == :commit
        puts("Committing...(commit_or_not: #{commit_or_not})")
      else
        puts("Not committing...(commit_or_not: #{commit_or_not})")
        raise(ActiveRecord::Rollback)
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
      break if done == how_many;
    end
    done
  end

  # Notes: 
  # - setting the updated_by column to audit the user who is deleting the record.
  # - avoid validation on that update - otherwise the delete will not occur.
  def delete_as_user(username)
    update_attribute(:updated_by, username) 
    Instance::AsServices.delete(id)
  rescue => e
    logger.error("delete_as_user exception: #{e.to_s}")
    raise
  end

end

