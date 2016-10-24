# frozen_string_literal: true

# Name scopes
module NameCategories
  extend ActiveSupport::Concern
  # Category constants
  SCIENTIFIC_CATEGORY = "scientific".freeze
  SCIENTIFIC_HYBRID_FORMULA_CATEGORY = "scientific hybrid formula".freeze
  SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY =
    "scientific hybrid formula unknown 2nd parent".freeze
  PHRASE = "phrase".freeze
  CULTIVAR_CATEGORY = "cultivar".freeze
  CULTIVAR_HYBRID_CATEGORY = "cultivar hybrid".freeze
  OTHER_CATEGORY = "other".freeze

  included do
  end
end
