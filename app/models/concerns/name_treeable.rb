# frozen_string_literal: true

# Names can be in a classification tree
module NameTreeable
  extend ActiveSupport::Concern

  def apc_as_json
    Rails.cache.fetch("#{cache_key}/apc_info", expires_in: 2.minutes) do
      JSON.load(open(Name::AsServices.in_apc_url(id)))
    end
  rescue => e
    logger.error("apc_as_json: #{e} for : #{Name::AsServices.in_apc_url(id)}")
    "[unknown - service error]"
  end

  def accepted_tree_version_element
    Tree.accepted.first.current_tree_version.name_in_version(self)
  end

  def draft_tree_version_element
    Tree.accepted.first.default_draft_version.name_in_version(self)
  end

  def accepted_in_some_way?
    tve = accepted_tree_version_element
    tve.present?
  end

  def apc?
    accepted_in_some_way?
  end

  def accepted_instance_id
    return nil unless accepted_in_some_way?
    accepted_tree_version_element.tree_element.instance_id
  end

  def apc_excluded?
    return nil unless accepted_in_some_way?
    accepted_tree_version_element.tree_element.excluded
  end

  def accepted_concept?
    accepted_in_some_way? && !apc_excluded?
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
