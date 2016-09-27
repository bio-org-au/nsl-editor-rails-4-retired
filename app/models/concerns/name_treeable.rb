# frozen_string_literal: true

# Names can be in a classification tree
module NameTreeable
  extend ActiveSupport::Concern
  included do
    # TODO: Needs a test
    has_one :apc_tree_path,
            (lambda do
               where "exists (select null from tree_arrangement ta where
             tree_id = ta.id and ta.description = 'Australian Plant Census')"
             end),
            class_name: "NameTreePath"
    # TODO: Needs a test
    has_one :apni_tree_path,
            (lambda do
               where "exists (select null from tree_arrangement ta where
               tree_id = ta.id and ta.description =
               'APNI names classification')"
             end),
            class_name: "NameTreePath"
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
