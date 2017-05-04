# frozen_string_literal: true

# Name scopes
module NameEnterable
  extend ActiveSupport::Concern
  include NameCategories
  included do
  end

  def status_options
    NameStatus.options_for_category(category)
  end

  def takes_name_element?
    !(category == NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category ==
        NameCategories::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY)
  end

  def takes_status?
    category == NameCategories::SCIENTIFIC_CATEGORY ||
      category == NameCategories::PHRASE
  end

  def takes_rank?
    category == NameCategories::SCIENTIFIC_CATEGORY ||
      category == NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY ||
      category == NameCategories::CULTIVAR_CATEGORY ||
      category == NameCategories::CULTIVAR_HYBRID_CATEGORY ||
      category == NameCategories::PHRASE
  end

  def takes_authors?
    category == NameCategories::SCIENTIFIC_CATEGORY
  end

  def takes_author_only?
    category == NameCategories::PHRASE
  end

  def requires_name_element?
    category == NameCategories::SCIENTIFIC_CATEGORY ||
      category == NameCategories::CULTIVAR_CATEGORY ||
      category == NameCategories::CULTIVAR_HYBRID_CATEGORY ||
      category == NameCategories::OTHER_CATEGORY
  end

  def needs_top_buttons?
    category == NameCategories::SCIENTIFIC_CATEGORY
  end

  def requires_higher_ranked_parent?
    category == NameCategories::SCIENTIFIC_CATEGORY
  end
end
