# frozen_string_literal: true

# Name scopes
module NameAuthorable
  extend ActiveSupport::Concern
  included do
    belongs_to :author
    belongs_to :ex_author, class_name: "Author"
    belongs_to :base_author, class_name: "Author"
    belongs_to :ex_base_author, class_name: "Author"
    belongs_to :sanctioning_author, class_name: "Author"
  end

  def author_and_ex_author_must_differ
    if author_id.present? && ex_author_id.present? && author_id == ex_author_id
      errors[:base] << "The ex-author cannot be the same as the author."
    end
  end

  def base_author_and_ex_base_author_must_differ
    return unless base_author_id.present? &&
                  ex_base_author_id.present? &&
                  base_author_id == ex_base_author_id
    errors[:base] << "The ex-base author cannot be the same as the base author."
  end
end
