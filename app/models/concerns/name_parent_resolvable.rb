module NameParentResolvable
  extend ActiveSupport::Concern

  def resolve_parent(params,which_parent)
    key_field = "#{which_parent}_id"
    ta_field = "#{which_parent}_typeahead"
    if params.key?(key_field)
      self.send("#{key_field}=", Name::AsResolvedTypeahead::ForParent.new(
        params[key_field],
        params[ta_field],
        which_parent.capitalize
      ).value)
    end
  end
end
