module ReferenceParentResolvable
  extend ActiveSupport::Concern

  def resolve_parent(params)
    field_name = 'parent'
    key_field = "#{field_name}_id"
    ta_field = "#{field_name}_typeahead"
    if params.key?(key_field)
      self.send("#{key_field}=", Reference::AsResolvedTypeahead::ForParent.new(
        params[key_field],
        params[ta_field],
        field_name.capitalize
      ).value)
    end
  end
end
