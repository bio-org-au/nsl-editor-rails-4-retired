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
#  Reference entity - books, papers, journals, etc
class Reference < ActiveRecord::Base
  include PgSearch
  require 'open-uri'
  self.table_name = "reference"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  strip_attributes

  attr_accessor :display_as, :message

  # https://github.com/Casecommons/pg_search
  pg_search_scope :search_citation_text_for,
                  against: :citation,
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "english",
                      prefix: "true",
                    }
                  }

  # https://robots.thoughtbot.com/optimizing-full-text-search-with-postgres-
  # tsvector-columns-and-triggers
  pg_search_scope :search_citation_tsv_for,
                  against: :citation,
                  using: {
                    tsearch: {
                      tsvector_column: "tsv",
                      dictionary: "english",
                      prefix: "true",
                    }
                  }

  scope :lower_citation_equals,
        ->(string) { where("lower(citation) = ? ", string.downcase) }
  scope :lower_citation_like,
        ->(string) { where("lower(citation) like ? ", string.tr("*", "%").downcase) }
  scope :not_duplicate,
        -> { where("duplicate_of_id is null") }
  scope :is_duplicate,
        -> { where("duplicate_of_id is not null") }

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

  belongs_to :ref_type, foreign_key: "ref_type_id"
  belongs_to :ref_author_role, foreign_key: "ref_author_role_id"
  belongs_to :author, foreign_key: "author_id"

  # Prevent parent references being destroyed; cannot see how to enforce
  # this via acts_as_tree.
  belongs_to :parent, class_name: Reference, foreign_key: "parent_id"
  has_many :children,
           class_name: "Reference",
           foreign_key:  "parent_id",
           dependent: :restrict_with_exception

  # acts_as_tree foreign_key: :duplicate_of_id, order: "title"
  # Cannot have 2 acts_as_tree in one model.
  belongs_to :duplicate_of,
             class_name: "Reference",
             foreign_key: "duplicate_of_id"
  has_many :duplicates,
           class_name: "Reference",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_exception

  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  belongs_to :language

  has_many :instances, foreign_key: "reference_id"
  has_many :name_instances,
           -> { where "cited_by_id is not null" },
           class_name: "Instance",
           foreign_key: "reference_id"
  has_many :novelties,
           -> { where "instance.instance_type_id in (select id from instance_type where primary_instance)" },
           class_name: "Instance",
           foreign_key: "reference_id"
  has_many :comments

  validates :published, inclusion: { in: [true, false] }
  validates_length_of :volume,
                      maximum: 50,
                      message: "cannot be longer than 50 characters"
  validates_length_of :edition,
                      maximum: 50,
                      message: "cannot be longer than 50 characters"
  validates_length_of :pages,
                      maximum: 255,
                      message: "cannot be longer than 255 characters"
  validates_presence_of :ref_type_id,
                        :author_id,
                        :ref_author_role_id,
                        message: "cannot be empty."
  # Title and display_title are mandatory columns, but many records have
  # simply a single space in these column. But a single space is not enough
  # to avoid the validates_presence_of test, so using this length test instead.
  validates :display_title, :title,
            length: { minimum: 1 }
  validates :year,
            numericality: { only_integer: true,
                            greater_than_or_equal_to: 1000,
                            less_than_or_equal_to: Time.now.year },
            allow_nil: true
  validates_exclusion_of :parent_id,
                         in: ->(reference) { [reference.id] },
                         allow_blank: true,
                         message: "and child cannot be the same record"
  validates_exclusion_of :duplicate_of_id,
                         in: ->(reference) { [reference.id] },
                         allow_blank: true,
                         message: "and master cannot be the same record"
  validates :language_id, presence: true
  validate :validate_parent
  validate :validate_fields_for_part

  ID_AND_AUDIT_FIELDS = %w(id
                           created_at
                           created_by
                           updated_at
                           updated_by
                           namespace_id
                           source_system
                           source_id
                           lock_version).freeze
  VIEW_ONLY_FIELDS = %w(author
                        ref_author_role_name
                        comma_after_edition
                        mark_as_ed_if_editor
                        parent_known_author
                        known_author_comma
                        publication_date_with_parens
                        verbatim_author
                        verbatim_citation
                        year_with_parens
                        known_author
                        verbatim_title).freeze
  SEARCH_LIMIT = 50
  DEFAULT_DESCRIPTOR = "citation" # for citation
  LEGAL_TO_ORDER_BY = { "p" => "parent_id",
                        "t" => "title",
                        "y" => "year",
                        "pd" => "publication_date",
                        # 'rt' => 'ref_type_name',  # order by ref_type.name?
                        "v" => "volume" }.freeze
  DEFAULT_ORDER_BY = "citation asc "

  before_validation :set_defaults
  before_create :set_defaults
  before_save :validate

  def has_children?
    children.size.positive?
  end

  def has_instances?
    instances.size.positive?
  end

  def validate
    logger.debug("validate")
    logger.debug("errors: #{errors[:base].size}")
    errors[:base].size.zero?
  end

  def ref_type_permits_parent?
    ref_type.parent_allowed?
  end

  def ref_type_message_about_parent
    if ref_type.blank?
      "Please choose a type."
    elsif ref_type_permits_parent?
      article = ref_type.parent.indefinite_article
      "#{ref_type.indefinite_article.capitalize} #{ref_type.name.downcase}
      type can
      have #{article} #{ref_type.parent.name.downcase} type parent."
    else
      "#{ref_type.indefinite_article.capitalize} #{ref_type.name.downcase}
      type cannot have a parent."
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
        logger.debug("Error in validate_parent current errors: #{errors.size}")
        errors.add(:parent_id,
                   "#{parent.ref_type.name.downcase} cannot contain
                   a #{ref_type.name.downcase}. Please change Type or Parent.")
      end
    else
      logger.debug("Error because parent is not allowed.")
      errors.add(:parent_id, "is not allowed for a #{ref_type.name}")
    end
  end

  # Reference that is a "part" of a paper has restricted fields
  def validate_fields_for_part
    return unless ref_type.part?
    errors.add(:volume, "is not allowed for a Part") if volume.present?
    errors.add(:edition, "is not allowed for a Part") if edition.present?
    errors.add(:year, "is not allowed for a Part") if year.present?
    errors.add(:publication_date, "is not allowed for a Part") if publication_date.present?
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update_attributes!(attributes)
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def anchor_id
    "Reference-#{id}"
  end

  def pages_useless?
    pages.blank? || pages.match(/null - null/)
  end

  def self.find_authors
    ->(name) { Author.where(" lower(name) = ?", name.downcase) }
  end

  def self.find_references
    ->(title) { Reference.where(" lower(title) = ?", title.downcase) }
  end

  def self.dummy_record
    find_by_title("Unknown")
  end

  def display_as_part_of_concept
    self.display_as = :reference_as_part_of_concept
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def set_defaults
    self.language_id = Language.default.id if language_id.blank?
    self.display_title = title if display_title.blank?
    self.namespace_id = Namespace.default.id
  end

  def set_citation!
    logger.debug("set_citation!")
    resource = Reference::AsServices.citation_strings_url(id)
    logger.debug("About to call the citation service: #{resource}")
    citation_json = JSON.load(open(resource))
    logger.debug("Back from the service call")
    logger.debug("before: citation_html: #{citation_html}")
    self.citation_html = citation_json["result"]["citationHtml"]
    logger.debug("after:  citation_html: #{citation_html}")
    logger.debug("before: citation: #{citation_html}")
    self.citation = citation_json["result"]["citation"]
    logger.debug("after:  citation: #{citation_html}")
    save!
  rescue => e
    logger.error("Exception rescued in ReferencesController#set_citation!")
    logger.error(e.to_s)
    logger.error("Check resource: #{resource}")
  end

  def parent_has_same_author?
    parent && !!author.name.match(/\A#{Regexp.escape(parent.author.name)}\z/)
  end

  # String referenceTitle = (reference.title && reference.title != 'Not set')
  # ? reference.title.fullStop() : ''
  def title_citation
    if title.strip =~ /\Anot set\z/i
      ""
    else
      if parent
        "<i>#{title.strip}</i>".radd_stop
      else
        "<i>#{title.strip}</i>"
      end
    end
  end

  def typeahead_display_value
    "#{citation} #{'[' + pages + ']' unless pages_useless?} \
      [#{ref_type.name.downcase}]"
  end

  def build_citations
    html_citation = build_html_citation
    [html_citation, html_citation.strip_tags]
  end

  def build_citation
    build_citations.last
  end

  def build_html_citation
    citation = ReferenceCitation.new(self)
    citation.html_version
  end

  def self.count_search_results(raw)
    logger.debug("Counting references")
    just_count_them = true
    count = search(raw, just_count_them)
    logger.debug(count)
    count
  end

  def ref_type_options
    if children.size.zero?
      RefType.options
    else
      RefType.options_for_parent_of(children.collect(&:ref_type))
    end
  end
end
