module ReferenceAuthorResolvable
  extend ActiveSupport::Concern

  def resolve_author(params)
    field_prefix = "author"
    key_field = "#{field_prefix}_id"
    ta_field = "#{field_prefix}_typeahead"
    if params.key?(key_field)
      self.send("#{key_field}=", Reference::AsResolvedTypeahead::ForAuthor.new(
        params[key_field],
        params[ta_field],
        field_prefix.capitalize
      ).value)
    end
  end
end
