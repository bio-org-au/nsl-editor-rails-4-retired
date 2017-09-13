# frozen_string_literal: true

# Name Parent resolvable typeahead parameters
module WorkspaceParentNameResolvable
  extend ActiveSupport::Concern

  def resolve_parent_name(params)
    Rails.logger.debug("resolve_parent for params: #{params.inspect}")
    key_field = :parent_name_id
    ta_field = :parent_name_typeahead
    if params.key?(key_field)
      send("#{key_field}=", Name::AsResolvedTypeahead::ForWorkspaceParent.new(
        params[key_field],
        params[ta_field].sub(/  *- *$/, "")
      ).value)
    else
      raise "Could not find key field: #{key_field}"
    end
  end
end
