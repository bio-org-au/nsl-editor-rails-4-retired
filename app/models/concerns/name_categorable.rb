# frozen_string_literal: true

# Name category concerns
module NameCategorable
  extend ActiveSupport::Concern
  include NameCategories

  def name_type_must_match_category
    return if NameType.option_ids_for_category(category).include?(name_type_id)
    errors.add(:name_type_id,
               "Wrong name type for category! Category: #{category} vs
               name type: #{name_type.name}.")
  end

  def category
    change_category_to.present? ? change_category_to : raw_category
  end

  RAW_CATEGORY = {
    "autonym" => NameCategories::SCIENTIFIC_CATEGORY,
    "hybrid formula unknown 2nd parent" =>
    NameCategories::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY,
    "named hybrid" => NameCategories::SCIENTIFIC_CATEGORY,
    "named hybrid autonym" => NameCategories::SCIENTIFIC_CATEGORY,
    "sanctioned" => NameCategories::SCIENTIFIC_CATEGORY,
    "scientific" => NameCategories::SCIENTIFIC_CATEGORY,
    "candidatus" => NameCategories::SCIENTIFIC_CATEGORY,
    "phrase name" => NameCategories::PHRASE,
    "cultivar hybrid formula" =>
    NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "graft/chimera" => NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "hybrid" => NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "hybrid autonym" => NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "hybrid formula parents known" =>
    NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "intergrade" => NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "formula" => NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
    "acra" => NameCategories::CULTIVAR_CATEGORY,
    # deprecated name type
    "acra hybrid" => NameCategories::CULTIVAR_HYBRID_CATEGORY,
    "cultivar" => NameCategories::CULTIVAR_CATEGORY,
    "cultivar hybrid" => NameCategories::CULTIVAR_HYBRID_CATEGORY,
    "pbr" => NameCategories::CULTIVAR_CATEGORY,
    # deprecated name type
    "pbr hybrid" => NameCategories::CULTIVAR_HYBRID_CATEGORY,
    "trade" => NameCategories::CULTIVAR_CATEGORY,
    # deprecated name type
    "trade hybrid" => NameCategories::CULTIVAR_HYBRID_CATEGORY,
    "[default]" => NameCategories::OTHER_CATEGORY,
    "[n/a]" => NameCategories::OTHER_CATEGORY,
    "[unknown]" => NameCategories::OTHER_CATEGORY,
    "common" => NameCategories::OTHER_CATEGORY,
    "informal" => NameCategories::OTHER_CATEGORY,
  }.freeze

  def raw_category
    RAW_CATEGORY[name_type.try("name").try("downcase")] || NameCategories::OTHER_CATEGORY
  end
end
