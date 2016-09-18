# frozen_string_literal: true

# Rails model for a view
class AcceptedConcept < ActiveRecord::Base
  self.table_name = "accepted_name_vw"
  self.primary_key = "id"
  APC_ACCEPTED = "ApcConcept"
  default_scope { where(type_code: APC_ACCEPTED) }
  belongs_to :name, foreign_key: "id"
end

