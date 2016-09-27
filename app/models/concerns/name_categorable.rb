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

  def raw_category
    case name_type.try("name")
    when "autonym"
      then NameCategories::SCIENTIFIC_CATEGORY
    when "hybrid formula unknown 2nd parent"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
    when "named hybrid"
      then NameCategories::SCIENTIFIC_CATEGORY
    when "named hybrid autonym"
      then NameCategories::SCIENTIFIC_CATEGORY
    when "sanctioned"
      then NameCategories::SCIENTIFIC_CATEGORY
    when "scientific"
      then NameCategories::SCIENTIFIC_CATEGORY
    when "phrase name"
      then NameCategories::SCIENTIFIC_CATEGORY
    when "cultivar hybrid formula"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "graft/chimera"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "hybrid"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "hybrid autonym"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "hybrid formula parents known"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "intergrade"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "formula"
      then NameCategories::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    when "acra"
      then NameCategories::CULTIVAR_CATEGORY
    # deprecated name type
    when "acra hybrid"
      then NameCategories::CULTIVAR_HYBRID_CATEGORY
    when "cultivar"
      then NameCategories::CULTIVAR_CATEGORY
    when "cultivar hybrid"
      then NameCategories::CULTIVAR_HYBRID_CATEGORY
    when "pbr"
      then NameCategories::CULTIVAR_CATEGORY
    # deprecated name type
    when "pbr hybrid"
      then NameCategories::CULTIVAR_HYBRID_CATEGORY
    when "trade"
      then NameCategories::CULTIVAR_CATEGORY
    # deprecated name type
    when "trade hybrid"
      then NameCategories::CULTIVAR_HYBRID_CATEGORY
    when "[default]"
      then NameCategories::OTHER_CATEGORY
    when "[n/a]"
      then NameCategories::OTHER_CATEGORY
    when "[unknown]"
      then NameCategories::OTHER_CATEGORY
    when "common"
      then NameCategories::OTHER_CATEGORY
    when "informal"
      then NameCategories::OTHER_CATEGORY
    else NameCategories::OTHER_CATEGORY
    end
  end
end
