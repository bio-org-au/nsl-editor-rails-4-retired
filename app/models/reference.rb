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


class Reference < ActiveRecord::Base
  self.table_name = 'reference'  
  self.primary_key = 'id'
  self.sequence_name = 'nsl_global_seq'
  strip_attributes

  extend AdvancedSearch
  extend SearchTools
  
  attr_accessor :display_as, :message
  scope :lower_citation_equals, ->(string) { where("lower(citation) = ? ",string.downcase) }
  scope :lower_citation_like, ->(string) { where("lower(citation) like ? ",string.gsub(/\*/,'%').downcase) }
  scope :not_duplicate, -> { where("duplicate_of_id is null") }

  scope :created_n_days_ago, ->(n) { where("current_date - created_at::date = ?",n)}
  scope :updated_n_days_ago, ->(n) { where("current_date - updated_at::date = ?",n)}
  scope :changed_n_days_ago, ->(n) { where("current_date - created_at::date = ? or current_date - updated_at::date = ?",n,n)}

  scope :created_in_the_last_n_days, ->(n) { where("current_date - created_at::date < ?",n)}
  scope :updated_in_the_last_n_days, ->(n) { where("current_date - updated_at::date < ?",n)}
  scope :changed_in_the_last_n_days, ->(n) { where("current_date - created_at::date < ? or current_date - updated_at::date < ?",n,n)}

  belongs_to :ref_type, foreign_key: 'ref_type_id'
  belongs_to :ref_author_role, foreign_key: 'ref_author_role_id'
  belongs_to :author, foreign_key: 'author_id'

  # Prevent parent references being destroyed; cannot see how to enforce this via acts_as_tree.
  belongs_to :parent, class_name: Reference , foreign_key: 'parent_id'
  has_many :children, 
           class_name: 'Reference', 
           foreign_key:  'parent_id', 
           dependent: :restrict_with_exception

  #acts_as_tree foreign_key: :duplicate_of_id, order: "title"  # Cannot have 2 acts_as_tree in one model.
  belongs_to :duplicate_of, 
             class_name: 'Reference', 
             foreign_key: 'duplicate_of_id'
  has_many :duplicates, 
           class_name: 'Reference', 
           foreign_key: 'duplicate_of_id', 
           dependent: :restrict_with_exception

  belongs_to :namespace, class_name: 'Namespace', foreign_key: 'namespace_id'
  belongs_to :language

  has_many :instances, foreign_key: 'reference_id'
  has_many :name_instances, -> { where 'cited_by_id is not null' }, class_name: 'Instance', foreign_key: 'reference_id'
  has_many :comments

  validates :published, inclusion: { in: [true, false] }
  validates_length_of :volume, maximum: 50, message: "cannot be longer than 50 characters"
  validates_length_of :edition, maximum: 50, message: "cannot be longer than 50 characters"
  validates_length_of :pages, maximum: 255, message: "cannot be longer than 255 characters"
  validates_presence_of :ref_type_id, :author_id, :ref_author_role_id, message: 'cannot be empty.'
  # Title and display_title are mandatory columns, but many records have simply a single space in these column.
  # But a single space is not enough to avoid the validates_presence_of test, so using this length test instead.
  validates :display_title, :title, 
    length: { minimum: 1 }  # title, display_title are mandatory columns but can consist of a single space.
  validates :year, numericality: {only_integer: true, greater_than_or_equal_to: 1000, less_than_or_equal_to: Time.now.year}, allow_nil: true
  validates_exclusion_of :parent_id, in: lambda{ |reference| [reference.id] },
    allow_blank: true, 
    message: 'and child cannot be the same record'
  validates_exclusion_of :duplicate_of_id, in: lambda{ |reference| [reference.id] }, 
    allow_blank: true, 
    message: 'and master cannot be the same record'
  validates :language_id, presence: true
  validate :validate_parent

  ID_AND_AUDIT_FIELDS = %w(id created_at created_by updated_at updated_by namespace_id source_system source_id lock_version)
  VIEW_ONLY_FIELDS = %w(author ref_author_role_name comma_after_edition \
    mark_as_ed_if_editor parent_known_author known_author_comma \
    publication_date_with_parens verbatim_author \
    verbatim_citation year_with_parens known_author verbatim_title)
  SEARCH_LIMIT = 50
  DEFAULT_DESCRIPTOR = 'citation' # for citation
  LEGAL_TO_ORDER_BY = {'p' => 'parent_id', 
                       't' => 'title', 
                       'y' => 'year', 
                       'pd' => 'publication_date', 
                       # 'rt' => 'ref_type_name',  # order by ref_type.name?
                       'v' => 'volume'} 
  DEFAULT_ORDER_BY = 'citation asc '
  
  before_validation :set_defaults
  before_create :set_defaults
  before_save :validate

  def has_children?
    children.size > 0
  end

  def has_instances?
    instances.size > 0
  end

  def validate
    logger.debug("validate")
    logger.debug("errors: #{self.errors[:base].size}")
    self.errors[:base].size == 0
  end

  def ref_type_permits_parent?
    ref_type.parent_allowed?
  end

  def ref_type_message_about_parent
    if ref_type.blank?
      "Please choose a type."
    elsif ref_type_permits_parent?
      "#{ref_type.indefinite_article.capitalize} #{ref_type.name.downcase} type can have #{ref_type.parent.indefinite_article} #{ref_type.parent.name.downcase} type parent."
    else
      "#{ref_type.indefinite_article.capitalize} #{ref_type.name.downcase} type cannot have a parent."
    end
  end
  
  def validate_parent
    logger.debug("validate parent")
    if parent_id.blank? 
      # ok
    elsif ref_type.parent_allowed? 
      # ok so far, because has parent and parent is allowed
      if ref_type.parent.name == parent.ref_type.name
        # ok because the parent is what we would expect
      else
        logger.debug("Found error in validate_parent current errors: #{errors.size}")
        errors.add(:parent_id,"#{parent.ref_type.name.downcase} cannot contain a #{ref_type.name.downcase}. Please change Type or Parent.")  
      end
    else
      logger.debug("Error because parent is not allowed.")
      errors.add(:parent_id,"is not allowed for a #{ref_type.name}")  
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes,username)
    self.updated_by = username
    update_attributes!(attributes)
  end

  def fresh?
    created_at > 1.hour.ago
  end
  
  def anchor_id
    "Reference-#{self.id}"
  end

  def pages_useless?
    pages.blank? || pages.match(/null - null/)
  end

  def self.find_authors
    lambda {|name| Author.where(' lower(name) = ?',name.downcase)}
  end

  def self.find_references
    lambda {|title| Reference.where(' lower(title) = ?',title.downcase)}
  end

  # Local lookup value hashes
  # #########################
  # These hashes are set up once each time the app starts
  # when application.rb calls the initialize_rtn and initialize_rar methods.
  # One aim is to avoid querying these lookups every request.
  # Also, storing them in the Reference class is the fastest option I've found - 
  # the next most efficient method I tried added ~ 0.1sec/request on average.
  # Of course, if there is a faster way or an equally fast way that is less
  # hacked, do it that way.  
  RTN = Hash.new  # Will hold a mapping from ref_type.id to ref_type.name.
  RAR = Hash.new  # Will hold a mapping from ref_author_role.id to ref_author_role.name.
  
  # Sets up a mapping from ref_type.id to ref_type.name.
  def self.initialize_rtn
    if RTN.size == 0
      logger.debug("Initializing RTN")
      RefType.all.each {|ref_type| RTN[ref_type.id] = ref_type.name}
    end
  end

  # Sets up a mapping from ref_author_role.id to ref_author_role.name.
  def self.initialize_rar
    if RAR.size == 0
      logger.debug("Initializing RAR")
      RefAuthorRole.all.each {|ref_author_role| RAR[ref_author_role.id] = ref_author_role.name}
    end
  end
  
  def self.show_RAR
    RAR.each {|n,v| logger.debug("#{n}: #{v}")}
  end
  
  def self.show_RTN
    RTN.each {|n,v| logger.debug("#{n}: #{v}")}.collect
  end
  
  def self.dummy_record
    self.find_by_title('Unknown')
  end
  
  def display_as_part_of_concept
    self.display_as = :reference_as_part_of_concept
  end

  # During development (at least) RAR goes empty - presumably on reload after changes.
  def ref_author_role_string
    RAR[self.ref_author_role_id].downcase  # downcase throws exception if nil returned from hash.
  rescue => e
    self.class.initialize_rar
    RAR[self.ref_author_role_id].downcase
  end

  def duplicate?
    !self.duplicate_of_id.blank?
  end

  def set_defaults
    self.language_id = Language.default.id if self.language_id.blank?
    self.display_title = title if self.display_title.blank?
    self.namespace_id = Namespace.apni.id
  end 
  
  def set_citation!
    logger.debug("set_citation!")
    resource = Reference::AsServices.citation_strings_url(id)
    logger.debug("About to call the citation service: #{resource}")
    citation_json = JSON.load(open(resource))
    logger.debug('Back from the service call')
    logger.debug("before: citation_html: #{citation_html}")
    self.citation_html = citation_json['result']['citationHtml']
    logger.debug("after:  citation_html: #{citation_html}")
    logger.debug("before: citation: #{citation_html}")
    self.citation = citation_json['result']['citation']
    logger.debug("after:  citation: #{citation_html}")
    self.save!
  rescue => e
    logger.error("Exception rescued in ReferencesController#set_citation!")
    logger.error(e.to_s)
    logger.error("Check resource: #{resource}")
  end

  def parent_has_same_author?
    parent && !!author.name.match(/\A#{Regexp.escape(parent.author.name)}\z/)
  end

  # String referenceTitle = (reference.title && reference.title != 'Not set') ? reference.title.fullStop() : ''
  def title_citation
    if title.strip.match(/\Anot set\z/i)
      ''
    else
      if self.parent
        "<i>#{title.strip}</i>".radd_stop
      else
        "<i>#{title.strip}</i>"
      end
    end
  end
 
  def build_citations
    html_citation = build_html_citation
    return html_citation, html_citation.strip_tags
  end

  def build_citation
    build_citations.last
  end

  def build_html_citation
    citation = ReferenceCitation.new(self)
    return citation.html_version
  end

  def self.count_search_results(raw)
    logger.debug('Counting references')
    just_count_them = true
    count = self.search(raw,just_count_them)
    logger.debug(count)
    count
  end

  # Order of search terms does not matter.
  def self.simple_search(search_limit, search_string, apply_limit)
    rejected_pairings = []
    where = ""
    binds = []
    info = [%Q(Reference search: "#{search_string}";)]
    search_string.gsub(/%+/,' ').split.each do |term|
      where += " lower(citation) like lower(?) and "
      binds.push "%#{term.downcase}%"
    end
    where += " 1=1 "
    results = Reference.where(binds.unshift(where)).order(DEFAULT_ORDER_BY).limit(search_limit)
    if apply_limit
      results = results.limit(search_limit) 
      if search_limit == 1
        info.push(" for up to 1 record") 
      else
        info.push(" for up to #{search_limit} records") 
      end
    else
      info.push(" for all records")
    end
    focus_anchor_id = results.size > 0 ? results.first.anchor_id : nil
    return results, rejected_pairings,results.size == search_limit,focus_anchor_id, info
  end

  # Order of search terms does not matter.
  def self.simple_count(search_string)
    where = ""
    binds = []
    search_string.split.each do |term|
      where += " lower(citation) like lower(?) and "
      binds.push "%#{term.downcase}%"
    end
    where += " 1=1 "
    count = Reference.where(binds.unshift(where)).count
    return count
  end

  def self.advanced_search(search_limit,search_string,apply_limit)
    info = [%Q(Reference search: "#{search_string}";)]
    where,
      binds,
      rejected_pairings = Reference.generic_bindings_to_where(self,
                                                            format_search_terms(DEFAULT_DESCRIPTOR,
                                                                                search_string))  
    where,binds,rejected_pairings = Reference.bindings_to_where(rejected_pairings,where,binds)
    order_by_binds,rejected_pairings = Reference.generic_bindings_to_order_by(rejected_pairings,
                                                                                LEGAL_TO_ORDER_BY) 
    order_by_binds.push(DEFAULT_ORDER_BY)
    order_by_binds.unshift(@order_by_override) if @order_by_override
    if rejected_pairings.size > 0
      results = []
    else
      results = Reference.where(binds.unshift(where)).order(order_by_binds)
      if apply_limit
        results = results.limit(search_limit) 
        if search_limit == 1
          info.push(" for up to 1 record") 
        else
          info.push(" for up to #{search_limit} records") 
        end
      else
        info.push(" for all records")
      end
    end
    focus_anchor_id = results.size > 0 ? results.first.anchor_id : nil
    return results, rejected_pairings,results.size == search_limit,focus_anchor_id, info
  end

  def self.advanced_count(search_string)
    where,
      binds,
      rejected_pairings = Reference.generic_bindings_to_where(self,
                                                            format_search_terms(DEFAULT_DESCRIPTOR,
                                                                                search_string))  
    where,binds,rejected_pairings = Reference.bindings_to_where(rejected_pairings,where,binds)
    if rejected_pairings.size > 0
      count = -1
    else
      count = Reference.where(binds.unshift(where)).count
    end
    count
  end

  def self.search(raw, limit = 100, just_count_them = false, exclude_common_and_cultivar = true, apply_limit = true)
    logger.debug(%Q(Reference search: "#{raw}" up to #{limit} records; exclude_common_and_cultivar: #{exclude_common_and_cultivar}; apply_limit: #{apply_limit}.))
    search_limit = limit
    search_string = raw
    info = %Q(Reference search: "#{search_string}")

    if Reference.search_is_simple?(raw)  
      if just_count_them
        return self.simple_count(search_string)
      else
        logger.debug('returning a simple search')
        return self.simple_search(search_limit,search_string.gsub(/\*/,'%'),apply_limit)
      end
    else
      if just_count_them
        return self.advanced_count(search_string)
      else
        return self.advanced_search(search_limit,search_string,apply_limit)
      end
    end
    #focus_anchor_id = results.size > 0 ? results.first.anchor_id : nil
    #return results, rejected_pairings,results.size == search_limit,focus_anchor_id
  end

  # This turns field descriptors into parts of a where clause.
  # It is for "specific" field descriptors.  
  # The "generic" field descriptors should have been consumed beforehand.
  def self.bindings_to_where(search_terms_array,where,binds)
    logger.debug("bindings_to_where: search terms array: #{search_terms_array.join(',')}; where: #{where}; binds: {binds}")
    rejected_pairings = []
    default_order_by = 'citation'
    order_by_binds = [default_order_by]
    search_terms_array.each do | pairing |
      logger.debug "pairing: #{pairing}"
      logger.debug "pairing class: #{pairing.class}"
      logger.debug "pairing size: #{pairing.size}"
      if pairing.class == String         
        case pairing.downcase
        when 'with-comments'
          where += " and exists (select null from comment where comment.reference_id = reference.id) "
        when 'no-year-no-pub-date'
          where += " and year is null and publication_date is null "
        when 'duplicate','d'
          where += " and duplicate_of_id is not null "
        end
      elsif pairing.size == 2         
        case pairing[0].downcase
        when 'with-comments'
          where += " and exists (select null from comment where comment.reference_id = reference.id and comment.text like ?) "
          binds.push(prepare_search_term_string(pairing[1]))
        when 'with-comments-by'
          where += " and exists (select null from comment where comment.reference_id = reference.id and (lower(comment.created_by) like ? or lower(comment.updated_by) like ?)) "
          binds.push(prepare_search_term_string(pairing[1]))
          binds.push(prepare_search_term_string(pairing[1]))
        when 'rc', 'ref-citation', 'citation'
          pairing[1].gsub(/%+/,' ').split.each do |term|
            where += " and lower(citation) like lower(?) "
            binds.push "%#{term.downcase}%"
          end
        when 'ra'
          where += " and author_id in (select id from author where lower(name) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'a'
          where += " and author_id in (select id from author where lower(name) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'author'
          where += " and author_id in (select id from author where lower(name) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'ref-author'
          where += " and author_id in (select id from author where lower(name) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'author-id'
          where += " and author_id = ? "
          binds.push(pairing[1].to_i)
        when 'ref-author-id'
          where += " and author_id = ? "
          binds.push(pairing[1].to_i)
        when 'bhl'
          where += " and lower(bhl_url) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'rbhl'
          where += " and lower(bhl_url) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'ref-bhl'
          where += " and lower(bhl_url) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'duplicate' || 'd'
          where += " and dUplicate_of_id is not null "
        when 'rd'
          where += " and duplicate_of_id is not null "
        when 'p'
          where += " and (id = ? or parent_id = ?) "
          parent_id = pairing[1].sub(/.*\(/,'').sub(/\)$/,'').to_i
          binds.push(parent_id)
          binds.push(parent_id)
          @order_by_override = ' case id when 1572 then 0 else 99 end '
        when 'rp'
          where += " and (id = ? or parent_id = ?) "
          parent_id = pairing[1].sub(/.*\(/,'').sub(/\)$/,'').to_i
          binds.push(parent_id)
          binds.push(parent_id)
          @order_by_override = ' case id when 1572 then 0 else 99 end '
        when 'pd'
          where += " and lower(publication_date) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'rpd'
          where += " and lower(publication_date) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'ref-publication-date'
          where += " and lower(publication_date) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'pt'
          where += " and exists (select null from reference parent where reference.parent_id = parent.id and lower(parent.title) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]).gsub(/ /,'%'))
        when 'rpt'
          where += " and exists (select null from reference parent where reference.parent_id = parent.id and lower(parent.title) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]).gsub(/ /,'%'))
        when 'ref-parent-title'
          where += " and exists (select null from reference parent where reference.parent_id = parent.id and lower(parent.title) like ?) "
          binds.push(Reference.prepare_search_term_string(pairing[1]).gsub(/ /,'%'))
        when 't'
          where += " and lower(title) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]).gsub(/ /,'%'))
        when 'rti'
          where += " and lower(title) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]).gsub(/ /,'%'))
        when 'ref-title'
          where += " and lower(title) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]).gsub(/ /,'%'))
        when 'rt'
          where += " and ref_type_id in (select id from ref_type rt where lower(rt.name) like ?) "
          binds.push(pairing[1].downcase + '%')
        when 'rty'
          where += " and ref_type_id in (select id from ref_type rt where lower(rt.name) like ?) "
          binds.push(pairing[1].downcase + '%')
        when 'ref-type'
          where += " and ref_type_id in (select id from ref_type rt where lower(rt.name) like ?) "
          binds.push(pairing[1].downcase + '%')
        when 'sa'
          where += " and lower(abbrev_title) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'rat'
          where += " and lower(abbrev_title) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'ref-abbrev-title'
          where += " and lower(abbrev_title) like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'v'
          where += " and volume like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'rv'
          where += " and volume like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'ref-volume'
          where += " and volume like ? "
          binds.push(Reference.prepare_search_term_string(pairing[1]))
        when 'y'
          where += " and year = ? "
          binds.push(pairing[1].strip)
        when 'ry'
          where += " and year = ? "
          binds.push(pairing[1].strip)
        else
          logger.debug('no match')
          rejected_pairings.push(pairing.join(':'))
          logger.error "Rejected pairing: #{pairing}"
        end
      else
        # Most likely an empty search criterion.
        rejected_pairings.push([pairing])
        logger.error "Rejected pairing: #{pairing}"
      end
    end
    where.sub!(/\A *and/,'')
    return where,binds,rejected_pairings
  end

  def self.order_this_record_first(*args)
    logger.debug("Order this record first: #{args.first}")
  end
        
  def self.legal_to_order_by?(raw)
    LEGAL_TO_ORDER_BY.include?(raw)
  end
  
  # Postgresql sorts the null ids to the end, unlike oracle, mysql
  # So treat nulls as zero and bring them to the top of the list.
  def self.processed_order_by_element(raw)
    if raw.downcase =~ /^parent_id\W/
      "coalesce(parent_id,0)"
    else
      raw
    end
  end
  
  def self.safe_order_by_elements(raw)
    safe = []
    raw.split(',').each do | component |
      field_descriptor = component.split.first
      if LEGAL_TO_ORDER_BY.has_key?(field_descriptor)
        if component.split.size == 2
          direction = case component.split.last.downcase
                      when 'a' then
                        'asc'
                      when 'd' then
                        'desc'
                      else
                        'asc'
                      end
        else
          direction = ''
        end
        safe.push(LEGAL_TO_ORDER_BY[field_descriptor] + " #{direction}")
      end
    end
    logger.debug("Safe order by elements: #{safe.inspect}")
    safe.reverse
  end

end


