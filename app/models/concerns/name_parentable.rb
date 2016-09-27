# frozen_string_literal: true

# Name scopes
module NameParentable
  extend ActiveSupport::Concern
  include NameCategories
  included do
    belongs_to :parent, class_name: "Name", foreign_key: "parent_id"
    has_many :children,
             class_name: "Name",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception
    belongs_to :second_parent,
               class_name: "Name", foreign_key: "second_parent_id"
    has_many :second_children,
             class_name: "Name",
             foreign_key: "second_parent_id",
             dependent: :restrict_with_exception
    has_many :just_second_children,
             -> { where "parent_id != second_parent_id" },
             class_name: "Name", foreign_key: "second_parent_id",
             dependent: :restrict_with_exception
  end

  def requires_parent?
    category != NameCategories::OTHER_CATEGORY &&
      name_rank.present? &&
      name_rank.has_parent?
  end

  def requires_parent_1?
    category != NameCategories::OTHER_CATEGORY
  end

  def takes_parent_1?
    category == NameCategories::SCIENTIFIC_CATEGORY ||
      category == NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == NameCategories::CULTIVAR_CATEGORY ||
      category == NameCategories::CULTIVAR_HYBRID_CATEGORY ||
      category ==
        NameCategories::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
  end

  def takes_parent_2?
    category == NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == NameCategories::CULTIVAR_HYBRID_CATEGORY
  end

  def requires_parent_2?
    category == NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == NameCategories::CULTIVAR_HYBRID_CATEGORY
  end

  def takes_hybrid_scoped_parent?
    category == NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category ==
        NameCategories::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
  end

  def takes_cultivar_scoped_parent?
    category == NameCategories::CULTIVAR_CATEGORY ||
      category == NameCategories::CULTIVAR_HYBRID_CATEGORY
  end

  def parent_rule
    case category
    when NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
         NameCategories::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
      then "hybrid - species and below or unranked if unranked"
    when NameCategories::CULTIVAR_HYBRID_CATEGORY,
         NameCategories::CULTIVAR_CATEGORY
      then "cultivar - genus and below, or unranked if unranked"
    else
      "ordinary - restricted by rank, or unranked if unranked"
    end
  end

  def second_parent_rule
    case category
    when NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
      then "hybrid - species and below or unranked if unranked"
    when NameCategories::CULTIVAR_HYBRID_CATEGORY
      then "cultivar - genus and below, or unranked if unranked"
    else ""
    end
  end

  def has_parent?
    parent_id.present?
  end

  def has_second_parent?
    second_parent.present?
  end

  def without_parent?
    !has_parent?
  end

  def needs_second_parent?
    hybrid? && !has_second_parent?
  end

  def descendents
    Name.all_children(id)
  end

  def combined_children
    Name.all_children(id)
  end
end
