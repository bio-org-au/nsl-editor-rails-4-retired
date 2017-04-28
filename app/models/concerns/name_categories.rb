# frozen_string_literal: true

# Name scopes
module NameCategories
  extend ActiveSupport::Concern
  # Category constants
  SCIENTIFIC_CATEGORY = "scientific"
  SCIENTIFIC_HYBRID_FORMULA_CATEGORY = "scientific hybrid formula"
  SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY =
    "scientific hybrid formula unknown 2nd parent"
  PHRASE = "phrase"
  CULTIVAR_CATEGORY = "cultivar"
  CULTIVAR_HYBRID_CATEGORY = "cultivar hybrid"
  OTHER_CATEGORY = "other"

  included do
  end
end
