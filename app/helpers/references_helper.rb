# frozen_string_literal: true
module ReferencesHelper
  def display_pages(pages = "")
    if pages.blank?
      ""
    elsif pages =~ /null - null/
      ""
    else
      " : #{pages}"
    end
  end
end
