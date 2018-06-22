# frozen_string_literal: true

# Names can be in a classification tree
module NameFamilyable
  extend ActiveSupport::Concern

  def should_have_family?
    name_rank.below_family? && category != NameCategories::OTHER_CATEGORY
  end

end
