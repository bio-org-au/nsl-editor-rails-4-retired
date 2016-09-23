module NameAuthorResolvable
  extend ActiveSupport::Concern

  def resolve_author(params,which_author)
    key_field = "#{which_author}_id"
    ta_field = "#{which_author}_typeahead"
    if params.key?(key_field)
      self.send("#{key_field}=", Name::AsResolvedTypeahead::ForAuthor.new(
        params[key_field],
        params[ta_field],
        which_author.capitalize
      ).value)
    end
  end
end
