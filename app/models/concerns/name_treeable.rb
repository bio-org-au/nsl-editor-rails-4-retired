# frozen_string_literal: true

# Names can be in a classification tree
module NameTreeable
  extend ActiveSupport::Concern
  included do

    has_one :accepted_in_some_way, foreign_key: "id"
    has_one :accepted_concept, foreign_key: "id"
  end

  def apc_as_json
    Rails.cache.fetch("#{cache_key}/apc_info", expires_in: 2.minutes) do
      JSON.load(open(Name::AsServices.in_apc_url(id)))
    end
  rescue => e
    logger.error("apc_as_json: #{e} for : #{Name::AsServices.in_apc_url(id)}")
    "[unknown - service error]"
  end

  def accepted_tree_version_element
    TreeVersionElement.find_by_sql(["SELECT tve.*
FROM tree_version_element tve
  JOIN tree t ON tve.tree_version_id = t.current_tree_version_id
  JOIN shard_config config ON t.name = config.value AND config.name = 'tree label'
  JOIN tree_element te ON tve.tree_element_id = te.id
WHERE te.name_id = :id", id: id]).first
  end

  def accepted_in_some_way?
    accepted_in_some_way.present?
  end

  def apc?
    accepted_in_some_way?
  end

  def apc_instance_id
    return nil unless accepted_in_some_way?
    accepted_in_some_way.instance_id
  end

  def apc_declared_bt?
    return nil unless accepted_in_some_way?
    accepted_in_some_way.declared_bt?
  end

  def apc_excluded?
    return nil unless accepted_in_some_way?
    accepted_in_some_way.excluded?
  end

  def accepted_concept?
    accepted_concept.present?
  end

  def sub_tree_size(level = 0)
    @size_ = 0 if level.zero?
    @size_ ||= 0
    @size_ += 1
    level += 1
    children.each do |child|
      @size_ += child.sub_tree_size(level)
    end
    @size_
  end

  def refresh_tree
    @tally ||= 0
    @tally += refresh_constructed_name_fields
    children.each do |child|
      @tally += child.refresh_tree
    end
    just_second_children.each do |child|
      @tally += child.refresh_tree
    end
    @tally
  end
end
