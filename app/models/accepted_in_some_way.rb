# frozen_string_literal: true

# Rails model for a view
class AcceptedInSomeWay < ActiveRecord::Base
  self.table_name = "accepted_name_vw"
  self.primary_key = "id"
  ACCEPTED = "ApcConcept".freeze
  EXCLUDED = "ApcExcluded".freeze
  DECLARED_BT = "DeclaredBt".freeze
  belongs_to :name, foreign_key: "id"

  def declared_bt?
    type_code == DECLARED_BT
  end

  def excluded?
    type_code == EXCLUDED
  end

  def accepted?
    type_code == ACCEPTED
  end
end
