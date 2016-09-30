# frozen_string_literal: true

# Reference validations
module ReferenceValidations
  extend ActiveSupport::Concern
  included do
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
    # to avoid the validates_presence_of test, so using this length test
    # instead.
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
  end

  def validate_parent
    return if parent_id.blank?
    validate_non_blank_parent
  end

  def validate_non_blank_parent
    if ref_type.parent_allowed?
      validate_parent_allowed
    else
      errors.add(:parent_id, "is not allowed for a #{ref_type.name}")
    end
  end

  def validate_parent_allowed
    return if ref_type.parent.name == parent.ref_type.name
    errors.add(:parent_id, incompatible_parent_type_message)
  end

  def incompatible_parent_type_message
    "#{parent.ref_type.name.downcase} cannot contain
    a #{ref_type.name.downcase}. Please change Type or Parent."
  end

  # Reference that is a "part" of a paper has restricted fields
  def validate_fields_for_part
    return unless ref_type.part?
    a_part_ref_cannot_have_publication_details
    a_part_ref_cannot_have_publication_details_date
  end

  def a_part_ref_cannot_have_publication_details
    errors.add(:volume, "is not allowed for a Part") if volume.present?
    errors.add(:edition, "is not allowed for a Part") if edition.present?
  end

  def a_part_ref_cannot_have_publication_details_date
    errors.add(:year, "is not allowed for a Part") if year.present?
    errors.add(:publication_date,
               "is not allowed for a Part") if publication_date.present?
  end
end
